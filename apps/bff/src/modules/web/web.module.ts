import { Module } from '@nestjs/common';
import { CatalogModule } from '../../catalog/catalog.module.js';
import { WebHomeController } from './web-home.controller.js';
import { WebHomeService } from './web-home.service.js';

@Module({
  imports: [CatalogModule],
  controllers: [WebHomeController],
  providers: [WebHomeService],
})
export class WebModule {}
