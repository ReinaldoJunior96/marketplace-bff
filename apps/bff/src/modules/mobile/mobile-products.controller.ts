import { Controller, Get, Param } from '@nestjs/common';
import { CatalogService } from '../../catalog/catalog.service.js';
import { MobileProductDetailDto } from './dto/mobile-product.dto.js';

@Controller('api/mobile/products')
export class MobileProductsController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get(':id')
  async findById(@Param('id') id: string): Promise<MobileProductDetailDto> {
    return new MobileProductDetailDto(await this.catalogService.findById(id));
  }
}
