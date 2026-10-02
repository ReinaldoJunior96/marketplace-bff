import { BadGatewayException, Injectable } from '@nestjs/common';
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

  async create(input: CreateOrderDto, correlationId: string): Promise<Order> {
    let response: Response;

    try {
      response = await fetch(`${this.baseUrl}/orders`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-correlation-id': correlationId,
        },
        body: JSON.stringify(input),
      });
    } catch {
      throw new BadGatewayException('Order Service is unavailable');
    }

    if (!response.ok) {
      throw new BadGatewayException('Order Service request failed');
    }

    return (await response.json()) as Order;
  }
}
