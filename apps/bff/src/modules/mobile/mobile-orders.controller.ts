import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Res,
} from '@nestjs/common';
import { CreateOrderPipe } from '../../orders/create-order.pipe.js';
import type { CreateOrderDto } from '../../orders/dto/create-order.dto.js';
import type { Order } from '../../orders/order.js';
import { OrdersService } from '../../orders/orders.service.js';
import type { MobileOrderTimelineDto } from './dto/mobile-activity.dto.js';
import { MobileOrderDto } from './dto/mobile-order.dto.js';
import { MobileActivityService } from './mobile-activity.service.js';

interface ResponseHeaderWriter {
  header(name: string, value: string): unknown;
}

@Controller('api/mobile/orders')
export class MobileOrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly activityService: MobileActivityService,
  ) {}

  @Get()
  async findAll(): Promise<MobileOrderDto[]> {
    const orders = await this.ordersService.findAll();
    return orders.map((order) => new MobileOrderDto(order));
  }

  @Get(':id/timeline')
  getTimeline(@Param('id') id: string): Promise<MobileOrderTimelineDto> {
    return this.activityService.getOrderTimeline(id);
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
