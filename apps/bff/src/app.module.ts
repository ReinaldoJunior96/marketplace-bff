import {
  type MiddlewareConsumer,
  Module,
  type NestModule,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { CommonModule } from './common/common.module.js';
import { CorrelationIdMiddleware } from './common/correlation-id.middleware.js';
import { HttpExceptionFilter } from './common/http-exception.filter.js';
import { MobileModule } from './modules/mobile/mobile.module.js';
import { HealthController } from './health.controller.js';
import { WebModule } from './modules/web/web.module.js';

@Module({
  imports: [CommonModule, CatalogModule, WebModule, MobileModule],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    CorrelationIdMiddleware,
    { provide: APP_FILTER, useClass: HttpExceptionFilter },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
