import {
  Injectable,
  Logger,
  type OnModuleDestroy,
  type OnModuleInit,
} from '@nestjs/common';
import amqp, { type ChannelModel, type ConfirmChannel } from 'amqplib';
import {
  NOTIFICATION_SENT_EVENT,
  type NotificationSentEvent,
} from '../events/notification-sent.event.js';
import { MARKETPLACE_EVENTS_EXCHANGE } from './rabbitmq.constants.js';

@Injectable()
export class RabbitMqPublisher implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMqPublisher.name);
  private connection?: ChannelModel;
  private channel?: ConfirmChannel;

  async onModuleInit(): Promise<void> {
    const url = process.env.RABBITMQ_URL;

    if (!url) {
      throw new Error('RABBITMQ_URL is required');
    }

    this.connection = await amqp.connect(url, {
      clientProperties: { connection_name: 'notification-service-publisher' },
    });
    this.channel = await this.connection.createConfirmChannel();
    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.channel?.close();
    await this.connection?.close();
  }

  async publishNotificationSent(event: NotificationSentEvent): Promise<void> {
    if (!this.channel) {
      throw new Error('RabbitMQ publisher channel is not available');
    }

    this.channel.publish(
      MARKETPLACE_EVENTS_EXCHANGE,
      NOTIFICATION_SENT_EVENT,
      Buffer.from(JSON.stringify(event)),
      {
        persistent: true,
        contentType: 'application/json',
        type: event.eventType,
        messageId: event.eventId,
        correlationId: event.correlationId,
        timestamp: Math.floor(Date.parse(event.occurredAt) / 1000),
      },
    );
    await this.channel.waitForConfirms();

    this.logger.log({
      eventType: event.eventType,
      eventId: event.eventId,
      orderId: event.data.orderId,
      customerId: event.data.customerId,
      correlationId: event.correlationId,
      message: 'Notification sent event published',
    });
  }
}
