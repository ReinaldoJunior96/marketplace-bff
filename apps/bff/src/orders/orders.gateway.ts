import { Injectable } from '@nestjs/common';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import type { CreateOrderDto } from './dto/create-order.dto.js';
import type { Order } from './order.js';

@Injectable()
export class OrdersGateway {
  private readonly baseUrl: string;

  constructor() {
    const url = process.env.ORDER_SERVICE_URL;

    if (!url) {
      throw new Error('ORDER_SERVICE_URL is required');
    }

    this.baseUrl = url.replace(/\/$/, '');
  }

  findAll(): Promise<Order[]> {
    return this.request<Order[]>('/orders');
  }

  async create(input: CreateOrderDto, correlationId: string): Promise<Order> {
    return this.request<Order>('/orders', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-correlation-id': correlationId,
      },
      body: JSON.stringify(input),
    });
  }

  private async request<T>(path: string, options?: RequestInit): Promise<T> {
    let response: Response;

    try {
      const url = `${this.baseUrl}${path}`;
      response = options ? await fetch(url, options) : await fetch(url);
    } catch {
      throw new DownstreamServiceUnavailableException('Order');
    }

    if (!response.ok) {
      throw new DownstreamServiceUnavailableException('Order');
    }

    return (await response.json()) as T;
  }
}
