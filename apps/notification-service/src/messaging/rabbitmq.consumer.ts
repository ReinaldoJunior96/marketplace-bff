import {
  Injectable,
  Logger,
  type OnModuleDestroy,
  type OnModuleInit,
} from '@nestjs/common';
import amqp, {
  type Channel,
  type ChannelModel,
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
  NOTIFICATION_ORDER_EVENTS_QUEUE,
} from './rabbitmq.constants.js';
import { RabbitMqPublisher } from './rabbitmq.publisher.js';

@Injectable()
export class RabbitMqConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMqConsumer.name);
  private connection?: ChannelModel;
  private channel?: Channel;

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
    this.channel = await this.connection.createChannel();

    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
    await this.channel.assertQueue(NOTIFICATION_ORDER_EVENTS_QUEUE, {
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

  async handleMessage(message: ConsumeMessage, channel: Channel): Promise<void> {
    try {
      const event = parseOrderCreatedEvent(message.content);

      this.logger.log({
        eventType: event.eventType,
        eventId: event.eventId,
        orderId: event.data.orderId,
        customerId: event.data.customerId,
        correlationId: event.correlationId,
        message: 'Order created event received',
      });

      this.notificationService.sendOrderCreated(event);
      const notificationSent = createNotificationSentEvent(event);
      await this.publisher.publishNotificationSent(notificationSent);
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
        message: 'Order created event processing failed',
        error: errorMessage,
      });
      channel.nack(message, false, false);
    }
  }
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
