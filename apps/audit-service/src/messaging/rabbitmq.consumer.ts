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
import { AuditService } from '../audit/audit.service.js';
import type { MarketplaceEvent } from '../events/marketplace-event.js';
import {
  AUDIT_MARKETPLACE_EVENTS_QUEUE,
  AUDIT_ROUTING_PATTERN,
  MARKETPLACE_EVENTS_EXCHANGE,
} from './rabbitmq.constants.js';

@Injectable()
export class RabbitMqConsumer implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMqConsumer.name);
  private connection?: ChannelModel;
  private channel?: Channel;
  private readonly processedEvents = new Set<string>();

  constructor(private readonly auditService: AuditService) {}

  async onModuleInit(): Promise<void> {
    const url = process.env.RABBITMQ_URL;

    if (!url) {
      throw new Error('RABBITMQ_URL is required');
    }

    this.connection = await amqp.connect(url, {
      clientProperties: { connection_name: 'audit-service' },
    });
    this.channel = await this.connection.createChannel();

    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
    await this.channel.assertQueue(AUDIT_MARKETPLACE_EVENTS_QUEUE, {
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
    channel: Channel,
  ): Promise<void> {
    try {
      const event = parseMarketplaceEvent(message.content);

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

      this.auditService.store(event);
      this.processedEvents.add(event.eventId);
      channel.ack(message);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown processing error';

      this.logger.error({
        message: 'Audit event processing failed',
        error: errorMessage,
      });
      channel.nack(message, false, false);
    }
  }
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
