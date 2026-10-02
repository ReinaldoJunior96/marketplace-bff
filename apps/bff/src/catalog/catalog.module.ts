import { Module } from '@nestjs/common';
import { CatalogController } from './catalog.controller.js';
import { CatalogGateway } from './catalog.gateway.js';
import { CatalogService } from './catalog.service.js';

@Module({
  controllers: [CatalogController],
  providers: [CatalogService, CatalogGateway],
  exports: [CatalogService],
})
export class CatalogModule {}
