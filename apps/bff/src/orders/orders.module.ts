import { Module } from '@nestjs/common';
import { OrdersGateway } from './orders.gateway.js';
import { OrdersService } from './orders.service.js';

@Module({
  providers: [OrdersService, OrdersGateway],
  exports: [OrdersService],
})
export class OrdersModule {}
