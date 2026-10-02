import { Controller, Get, Param } from '@nestjs/common';
import { CatalogService } from './catalog.service.js';
import type { Product } from './product.js';

@Controller('api/catalog/products')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get()
  findAll(): Promise<Product[]> {
    return this.catalogService.findAll();
  }

  @Get(':id')
  findById(@Param('id') id: string): Promise<Product> {
    return this.catalogService.findById(id);
  }
}
