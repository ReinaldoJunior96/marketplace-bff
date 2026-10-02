import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import type { CreateOrderDto } from './dto/create-order.dto.js';
import type { Order } from './order.js';
import { OrdersGateway } from './orders.gateway.js';

export interface CreateOrderResult {
  order: Order;
  correlationId: string;
}

@Injectable()
export class OrdersService {
  constructor(private readonly ordersGateway: OrdersGateway) {}

  findAll(): Promise<Order[]> {
    return this.ordersGateway.findAll();
  }

  async create(
    input: CreateOrderDto,
    requestedCorrelationId?: string,
  ): Promise<CreateOrderResult> {
    const correlationId = requestedCorrelationId?.trim() || randomUUID();
    const order = await this.ordersGateway.create(input, correlationId);

    return { order, correlationId };
  }
}
