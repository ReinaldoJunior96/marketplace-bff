import { Controller, Get, Param } from '@nestjs/common';
import type { Product } from './product.js';
import { ProductsService } from './products.service.js';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll(): Product[] {
    return this.productsService.findAll();
  }

  @Get(':id')
  findById(@Param('id') id: string): Product {
    return this.productsService.findById(id);
  }
}
