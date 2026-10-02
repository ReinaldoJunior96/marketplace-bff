import { randomUUID } from 'node:crypto';
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { RabbitMqPublisher } from '../messaging/rabbitmq.publisher.js';
import type { CreateOrderDto } from './dto/create-order.dto.js';
import {
  ORDER_CREATED_EVENT,
  type OrderCreatedEvent,
} from './events/order-created.event.js';
import type { Order } from './order.js';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);
  private readonly orders = new Map<string, Order>();

  constructor(private readonly publisher: RabbitMqPublisher) {}

  async create(input: CreateOrderDto, correlationId: string): Promise<Order> {
    const order: Order = {
      id: randomUUID(),
      customerId: input.customerId,
      items: input.items.map((item) => ({
        productId: item.productId,
        quantity: item.quantity,
      })),
      status: 'CREATED',
      createdAt: new Date().toISOString(),
    };

    this.orders.set(order.id, order);

    const event: OrderCreatedEvent = {
      eventId: randomUUID(),
      eventType: ORDER_CREATED_EVENT,
      occurredAt: new Date().toISOString(),
      correlationId,
      data: {
        orderId: order.id,
        customerId: order.customerId,
        items: order.items.map((item) => ({
          productId: item.productId,
          quantity: item.quantity,
        })),
        status: order.status,
      },
    };

    await this.publisher.publishOrderCreated(event);
    this.logger.log({
      event: event.eventType,
      orderId: order.id,
      correlationId,
      message: 'Order created event published',
    });

    return order;
  }

  findAll(): Order[] {
    return Array.from(this.orders.values());
  }

  findById(id: string): Order {
    const order = this.orders.get(id);

    if (!order) {
      throw new NotFoundException(`Order ${id} not found`);
    }

    return order;
  }
}
