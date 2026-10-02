import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { MobileModule } from './modules/mobile/mobile.module.js';
import { WebModule } from './modules/web/web.module.js';

@Module({
  imports: [CatalogModule, WebModule, MobileModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
