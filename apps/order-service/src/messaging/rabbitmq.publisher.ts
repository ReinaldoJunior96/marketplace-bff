import {
  Injectable,
  type OnModuleDestroy,
  type OnModuleInit,
} from '@nestjs/common';
import amqp, { type ChannelModel, type ConfirmChannel } from 'amqplib';
import {
  ORDER_CREATED_EVENT,
  type OrderCreatedEvent,
} from '../orders/events/order-created.event.js';
import { MARKETPLACE_EVENTS_EXCHANGE } from './rabbitmq.constants.js';

@Injectable()
export class RabbitMqPublisher implements OnModuleInit, OnModuleDestroy {
  private connection?: ChannelModel;
  private channel?: ConfirmChannel;
  private ready = false;

  async onModuleInit(): Promise<void> {
    const url = process.env.RABBITMQ_URL;

    if (!url) {
      throw new Error('RABBITMQ_URL is required');
    }

    this.connection = await amqp.connect(url, {
      clientProperties: { connection_name: 'order-service' },
    });
    this.connection.on('close', () => {
      this.ready = false;
    });
    this.connection.on('error', () => {
      this.ready = false;
    });
    this.channel = await this.connection.createConfirmChannel();
    await this.channel.assertExchange(MARKETPLACE_EVENTS_EXCHANGE, 'topic', {
      durable: true,
    });
    this.ready = true;
  }

  async onModuleDestroy(): Promise<void> {
    this.ready = false;
    await this.channel?.close();
    await this.connection?.close();
  }

  isReady(): boolean {
    return this.ready;
  }

  async publishOrderCreated(event: OrderCreatedEvent): Promise<void> {
    if (!this.channel) {
      throw new Error('RabbitMQ channel is not available');
    }

    this.channel.publish(
      MARKETPLACE_EVENTS_EXCHANGE,
      ORDER_CREATED_EVENT,
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
  }
}
