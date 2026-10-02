import {
  Injectable,
  Logger,
  type OnModuleDestroy,
  type OnModuleInit,
} from '@nestjs/common';
import amqp, {
  type ChannelModel,
  type ConfirmChannel,
  type ConsumeMessage,
} from 'amqplib';
import { createNotificationSentEvent } from '../events/notification-sent.event.js';
import {
  ORDER_CREATED_EVENT,
  type OrderCreatedEvent,
} from '../events/order-created.event.js';
import { NotificationService } from '../notifications/notification.service.js';
import {
  MARKETPLACE_EVENTS_EXCHANGE,
  NOTIFICATION_ORDER_EVENTS_DLQ,
  NOTIFICATION_ORDER_EVENTS_QUEUE,
  NOTIFICATION_ORDER_EVENTS_RETRY_QUEUE,
} from './rabbitmq.constants.js';
import { RabbitMqPublisher } from './rabbitmq.publisher.js';

@Injectable()
export class RabbitMqConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMqConsumer.name);
  private connection?: ChannelModel;
  private channel?: ConfirmChannel;
  private readonly processedEvents = new Set<string>();
  private readonly maxRetries = readNonNegativeInteger(
    'EVENT_RETRY_MAX_ATTEMPTS',
    2,
  );
  private readonly retryDelayMs = readPositiveInteger(
    'EVENT_RETRY_DELAY_MS',
    1_000,
  );

  constructor(
    private readonly notificationService: NotificationService,
    private readonly publisher: RabbitMqPublisher,
  ) {}

  async onModuleInit(): Promise<void> {
    const url = process.env.RABBITMQ_URL;

    if (!url) {
      throw new Error('RABBITMQ_URL is required');
    }

    this.connection = await amqp.connect(url, {
      clientProperties: { connection_name: 'notification-service' },
    });
    this.channel = await this.connection.createConfirmChannel();

    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
    await this.channel.assertQueue(NOTIFICATION_ORDER_EVENTS_QUEUE, {
      durable: true,
    });
    await this.channel.assertQueue(NOTIFICATION_ORDER_EVENTS_RETRY_QUEUE, {
      durable: true,
      arguments: {
        'x-message-ttl': this.retryDelayMs,
        'x-dead-letter-exchange': '',
        'x-dead-letter-routing-key': NOTIFICATION_ORDER_EVENTS_QUEUE,
      },
    });
    await this.channel.assertQueue(NOTIFICATION_ORDER_EVENTS_DLQ, {
      durable: true,
    });
    await this.channel.bindQueue(
      NOTIFICATION_ORDER_EVENTS_QUEUE,
      MARKETPLACE_EVENTS_EXCHANGE,
      ORDER_CREATED_EVENT,
    );
    await this.channel.prefetch(1);
    await this.channel.consume(
      NOTIFICATION_ORDER_EVENTS_QUEUE,
      (message) => {
        if (message) {
          void this.handleMessage(message, this.channel!);
        }
      },
      { noAck: false },
    );
  }

  async onModuleDestroy(): Promise<void> {
    await this.channel?.close();
    await this.connection?.close();
  }

  async handleMessage(
    message: ConsumeMessage,
    channel: ConfirmChannel,
  ): Promise<void> {
    let event: OrderCreatedEvent | undefined;
    const attempt = getRetryCount(message) + 1;

    try {
      event = parseOrderCreatedEvent(message.content);

      if (this.processedEvents.has(event.eventId)) {
        this.logger.warn({
          service: 'notification-service',
          eventId: event.eventId,
          eventType: event.eventType,
          correlationId: event.correlationId,
          message: 'Duplicate event ignored',
        });
        channel.ack(message);
        return;
      }

      if (shouldSimulateFailure(event.eventId)) {
        throw new Error('Simulated development failure');
      }

      this.logger.log({
        eventType: event.eventType,
        eventId: event.eventId,
        orderId: event.data.orderId,
        customerId: event.data.customerId,
        correlationId: event.correlationId,
        attempt,
        message: 'Order created event received',
      });

      this.notificationService.sendOrderCreated(event);
      const notificationSent = createNotificationSentEvent(event);
      await this.publisher.publishNotificationSent(notificationSent);
      this.processedEvents.add(event.eventId);
      channel.ack(message);
      this.logger.log({
        eventType: event.eventType,
        eventId: event.eventId,
        orderId: event.data.orderId,
        customerId: event.data.customerId,
        correlationId: event.correlationId,
        message: 'Order created event acknowledged',
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown processing error';

      this.logger.error({
        service: 'notification-service',
        eventId: event?.eventId ?? message.properties?.messageId,
        eventType: event?.eventType ?? message.properties?.type,
        correlationId:
          event?.correlationId ?? message.properties?.correlationId,
        attempt,
        message: 'Order created event processing failed',
        error: errorMessage,
      });

      if (attempt <= this.maxRetries) {
        channel.sendToQueue(
          NOTIFICATION_ORDER_EVENTS_RETRY_QUEUE,
          message.content,
          retryProperties(message, attempt),
        );
        await channel.waitForConfirms();
        channel.ack(message);
        this.logger.warn({
          service: 'notification-service',
          eventId: event?.eventId ?? message.properties?.messageId,
          eventType: event?.eventType ?? message.properties?.type,
          correlationId:
            event?.correlationId ?? message.properties?.correlationId,
          attempt,
          maxAttempts: this.maxRetries + 1,
          message: 'Event scheduled for retry',
        });
      } else {
        channel.sendToQueue(
          NOTIFICATION_ORDER_EVENTS_DLQ,
          message.content,
          failedMessageProperties(message, errorMessage),
        );
        await channel.waitForConfirms();
        channel.ack(message);
        this.logger.error({
          service: 'notification-service',
          eventId: event?.eventId ?? message.properties?.messageId,
          eventType: event?.eventType ?? message.properties?.type,
          correlationId:
            event?.correlationId ?? message.properties?.correlationId,
          attempt,
          message: 'Event forwarded to dead letter queue',
          queue: NOTIFICATION_ORDER_EVENTS_DLQ,
        });
      }
    }
  }
}

function failedMessageProperties(message: ConsumeMessage, reason: string) {
  return {
    ...retryProperties(message, getRetryCount(message)),
    headers: {
      ...message.properties?.headers,
      'x-failure-reason': reason,
    },
  };
}

function shouldSimulateFailure(eventId: string): boolean {
  return (
    process.env.NODE_ENV === 'development' &&
    process.env.DEV_FAIL_EVENT_ID !== undefined &&
    process.env.DEV_FAIL_EVENT_ID !== '' &&
    process.env.DEV_FAIL_EVENT_ID === eventId
  );
}

function getRetryCount(message: ConsumeMessage): number {
  const value = message.properties?.headers?.['x-retry-count'];
  return typeof value === 'number' && Number.isInteger(value) && value >= 0
    ? value
    : 0;
}

function retryProperties(message: ConsumeMessage, retryCount: number) {
  return {
    persistent: true,
    contentType: message.properties?.contentType ?? 'application/json',
    type: message.properties?.type,
    messageId: message.properties?.messageId,
    correlationId: message.properties?.correlationId,
    timestamp: message.properties?.timestamp,
    headers: {
      ...message.properties?.headers,
      'x-retry-count': retryCount,
    },
  };
}

function readNonNegativeInteger(name: string, fallback: number): number {
  const value = process.env[name];
  if (value === undefined) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${name} must be a non-negative integer`);
  }
  return parsed;
}

function readPositiveInteger(name: string, fallback: number): number {
  const value = process.env[name];
  if (value === undefined) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return parsed;
}

function parseOrderCreatedEvent(content: Buffer): OrderCreatedEvent {
  const value: unknown = JSON.parse(content.toString('utf8'));

  if (!isRecord(value) || !isRecord(value.data)) {
    throw new Error('Invalid order.created event');
  }

  const hasValidItems =
    Array.isArray(value.data.items) &&
    value.data.items.every(
      (item) =>
        isRecord(item) &&
        typeof item.productId === 'string' &&
        typeof item.quantity === 'number',
    );

  if (
    value.eventType !== ORDER_CREATED_EVENT ||
    typeof value.eventId !== 'string' ||
    typeof value.occurredAt !== 'string' ||
    typeof value.correlationId !== 'string' ||
    typeof value.data.orderId !== 'string' ||
    typeof value.data.customerId !== 'string' ||
    value.data.status !== 'CREATED' ||
    !hasValidItems
  ) {
    throw new Error('Invalid order.created event');
  }

  return value as unknown as OrderCreatedEvent;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}
