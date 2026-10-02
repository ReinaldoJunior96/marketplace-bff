import { Body, Controller, Headers, Post, Res } from '@nestjs/common';
import { CreateOrderPipe } from '../../orders/create-order.pipe.js';
import type { CreateOrderDto } from '../../orders/dto/create-order.dto.js';
import type { Order } from '../../orders/order.js';
import { OrdersService } from '../../orders/orders.service.js';

interface ResponseHeaderWriter {
  header(name: string, value: string): unknown;
}

@Controller('api/web/orders')
export class WebOrdersController {
  constructor(private readonly ordersService: OrdersService) {}

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
