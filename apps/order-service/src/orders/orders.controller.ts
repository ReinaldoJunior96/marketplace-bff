import { randomUUID } from 'node:crypto';
import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';
import { CreateOrderDto } from './dto/create-order.dto.js';
import type { Order } from './order.js';
import { OrdersService } from './orders.service.js';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(
    @Body() input: CreateOrderDto,
    @Headers('x-correlation-id') correlationId?: string,
  ): Promise<Order> {
    return this.ordersService.create(
      input,
      correlationId?.trim() || randomUUID(),
    );
  }

  @Get()
  findAll(): Order[] {
    return this.ordersService.findAll();
  }

  @Get(':id')
  findById(@Param('id') id: string): Order {
    return this.ordersService.findById(id);
  }
}
