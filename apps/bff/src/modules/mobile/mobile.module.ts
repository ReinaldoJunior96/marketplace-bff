import { Module } from '@nestjs/common';
import { CatalogModule } from '../../catalog/catalog.module.js';
import { MobileHomeController } from './mobile-home.controller.js';
import { MobileHomeService } from './mobile-home.service.js';

@Module({
  imports: [CatalogModule],
  controllers: [MobileHomeController],
  providers: [MobileHomeService],
})
export class MobileModule {}
