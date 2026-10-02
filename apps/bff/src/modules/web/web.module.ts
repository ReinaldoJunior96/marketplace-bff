import { Module } from '@nestjs/common';
import { CatalogModule } from '../../catalog/catalog.module.js';
import { OrdersModule } from '../../orders/orders.module.js';
import { WebHomeController } from './web-home.controller.js';
import { WebHomeService } from './web-home.service.js';
import { WebOrdersController } from './web-orders.controller.js';

@Module({
  imports: [CatalogModule, OrdersModule],
  controllers: [WebHomeController, WebOrdersController],
  providers: [WebHomeService],
})
export class WebModule {}
