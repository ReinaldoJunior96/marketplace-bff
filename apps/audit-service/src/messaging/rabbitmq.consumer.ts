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
import { AuditService } from '../audit/audit.service.js';
import type { MarketplaceEvent } from '../events/marketplace-event.js';
import {
  AUDIT_MARKETPLACE_EVENTS_QUEUE,
  AUDIT_MARKETPLACE_EVENTS_DLQ,
  AUDIT_MARKETPLACE_EVENTS_RETRY_QUEUE,
  AUDIT_ROUTING_PATTERN,
  MARKETPLACE_EVENTS_EXCHANGE,
} from './rabbitmq.constants.js';

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

  constructor(private readonly auditService: AuditService) {}

  async onModuleInit(): Promise<void> {
    const url = process.env.RABBITMQ_URL;

    if (!url) {
      throw new Error('RABBITMQ_URL is required');
    }

    this.connection = await amqp.connect(url, {
      clientProperties: { connection_name: 'audit-service' },
    });
    this.channel = await this.connection.createConfirmChannel();

    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
    await this.channel.assertQueue(AUDIT_MARKETPLACE_EVENTS_QUEUE, {
      durable: true,
    });
    await this.channel.assertQueue(AUDIT_MARKETPLACE_EVENTS_RETRY_QUEUE, {
      durable: true,
      arguments: {
        'x-message-ttl': this.retryDelayMs,
        'x-dead-letter-exchange': '',
        'x-dead-letter-routing-key': AUDIT_MARKETPLACE_EVENTS_QUEUE,
      },
    });
    await this.channel.assertQueue(AUDIT_MARKETPLACE_EVENTS_DLQ, {
      durable: true,
    });
    await this.channel.bindQueue(
      AUDIT_MARKETPLACE_EVENTS_QUEUE,
      MARKETPLACE_EVENTS_EXCHANGE,
      AUDIT_ROUTING_PATTERN,
    );
    await this.channel.prefetch(1);
    await this.channel.consume(
      AUDIT_MARKETPLACE_EVENTS_QUEUE,
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
    let event: MarketplaceEvent | undefined;
    const attempt = getRetryCount(message) + 1;

    try {
      event = parseMarketplaceEvent(message.content);

      if (this.processedEvents.has(event.eventId)) {
        this.logger.warn({
          service: 'audit-service',
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
        service: 'audit-service',
        eventId: event.eventId,
        eventType: event.eventType,
        correlationId: event.correlationId,
        attempt,
        message: 'Audit event received',
      });
      this.auditService.store(event);
      this.processedEvents.add(event.eventId);
      channel.ack(message);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown processing error';

      this.logger.error({
        service: 'audit-service',
        eventId: event?.eventId ?? message.properties?.messageId,
        eventType: event?.eventType ?? message.properties?.type,
        correlationId:
          event?.correlationId ?? message.properties?.correlationId,
        attempt,
        message: 'Audit event processing failed',
        error: errorMessage,
      });

      if (attempt <= this.maxRetries) {
        channel.sendToQueue(
          AUDIT_MARKETPLACE_EVENTS_RETRY_QUEUE,
          message.content,
          retryProperties(message, attempt),
        );
        await channel.waitForConfirms();
        channel.ack(message);
        this.logger.warn({
          service: 'audit-service',
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
          AUDIT_MARKETPLACE_EVENTS_DLQ,
          message.content,
          failedMessageProperties(message, errorMessage),
        );
        await channel.waitForConfirms();
        channel.ack(message);
        this.logger.error({
          service: 'audit-service',
          eventId: event?.eventId ?? message.properties?.messageId,
          eventType: event?.eventType ?? message.properties?.type,
          correlationId:
            event?.correlationId ?? message.properties?.correlationId,
          attempt,
          message: 'Event forwarded to dead letter queue',
          queue: AUDIT_MARKETPLACE_EVENTS_DLQ,
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

function parseMarketplaceEvent(content: Buffer): MarketplaceEvent {
  const value: unknown = JSON.parse(content.toString('utf8'));

  if (
    !isRecord(value) ||
    typeof value.eventId !== 'string' ||
    typeof value.eventType !== 'string' ||
    typeof value.correlationId !== 'string' ||
    typeof value.occurredAt !== 'string' ||
    !('data' in value)
  ) {
    throw new Error('Invalid marketplace event');
  }

  return value as unknown as MarketplaceEvent;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}
