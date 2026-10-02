import { Module } from '@nestjs/common';
import { AuditModule } from '../../audit/audit.module.js';
import { CatalogModule } from '../../catalog/catalog.module.js';
import { OrdersModule } from '../../orders/orders.module.js';
import { MobileActivityService } from './mobile-activity.service.js';
import { MobileHomeController } from './mobile-home.controller.js';
import { MobileHomeService } from './mobile-home.service.js';
import { MobileNotificationsController } from './mobile-notifications.controller.js';
import { MobileOrdersController } from './mobile-orders.controller.js';
import { MobileProductsController } from './mobile-products.controller.js';

@Module({
  imports: [AuditModule, CatalogModule, OrdersModule],
  controllers: [
    MobileHomeController,
    MobileNotificationsController,
    MobileOrdersController,
    MobileProductsController,
  ],
  providers: [MobileActivityService, MobileHomeService],
})
export class MobileModule {}
