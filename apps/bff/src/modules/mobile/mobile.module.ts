import { Module } from '@nestjs/common';
import { CatalogModule } from '../../catalog/catalog.module.js';
import { OrdersModule } from '../../orders/orders.module.js';
import { MobileHomeController } from './mobile-home.controller.js';
import { MobileHomeService } from './mobile-home.service.js';
import { MobileOrdersController } from './mobile-orders.controller.js';

@Module({
  imports: [CatalogModule, OrdersModule],
  controllers: [MobileHomeController, MobileOrdersController],
  providers: [MobileHomeService],
})
export class MobileModule {}
