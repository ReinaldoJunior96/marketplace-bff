import { Module } from '@nestjs/common';
import { HealthController } from './health.controller.js';
import { OrdersModule } from './orders/orders.module.js';

@Module({
  imports: [OrdersModule],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
