import { Controller, Get } from '@nestjs/common';
import type { WebHomeDto } from './dto/web-product.dto.js';
import { WebHomeService } from './web-home.service.js';

@Controller('api/web')
export class WebHomeController {
  constructor(private readonly webHomeService: WebHomeService) {}

  @Get('home')
  getHome(): Promise<WebHomeDto> {
    return this.webHomeService.getHome();
  }
}
