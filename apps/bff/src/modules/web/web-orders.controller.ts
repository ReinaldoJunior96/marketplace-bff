import { Body, Controller, Get, Headers, Post, Res } from '@nestjs/common';
import { CreateOrderPipe } from '../../orders/create-order.pipe.js';
import type { CreateOrderDto } from '../../orders/dto/create-order.dto.js';
import type { Order } from '../../orders/order.js';
import { OrdersService } from '../../orders/orders.service.js';
import { WebOrderDto } from './dto/web-order.dto.js';

interface ResponseHeaderWriter {
  header(name: string, value: string): unknown;
}

@Controller('api/web/orders')
export class WebOrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  async findAll(): Promise<WebOrderDto[]> {
    const orders = await this.ordersService.findAll();
    return orders.map((order) => new WebOrderDto(order));
  }

  @Post()
  async create(
    @Body(CreateOrderPipe) input: CreateOrderDto,
    @Headers('x-correlation-id') correlationId: string | undefined,
    @Res({ passthrough: true }) response: ResponseHeaderWriter,
  ): Promise<Order> {
    const result = await this.ordersService.create(input, correlationId);
    response.header('x-correlation-id', result.correlationId);
    return result.order;
  }
}
