import { Controller, Get } from '@nestjs/common';
import type { MobileHomeDto } from './dto/mobile-product.dto.js';
import { MobileHomeService } from './mobile-home.service.js';

@Controller('api/mobile')
export class MobileHomeController {
  constructor(private readonly mobileHomeService: MobileHomeService) {}

  @Get('home')
  getHome(): Promise<MobileHomeDto> {
    return this.mobileHomeService.getHome();
  }
}
