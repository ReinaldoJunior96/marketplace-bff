import { Controller, Get, Param } from '@nestjs/common';
import type { Product } from './product.js';
import { ProductsService } from './products.service.js';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  async findAll(): Promise<Product[]> {
    await simulateDevelopmentDelay();
    return this.productsService.findAll();
  }

  @Get(':id')
  async findById(@Param('id') id: string): Promise<Product> {
    await simulateDevelopmentDelay();
    return this.productsService.findById(id);
  }
}

async function simulateDevelopmentDelay(): Promise<void> {
  if (process.env.NODE_ENV !== 'development') return;

  const delayMs = Number(process.env.DEV_RESPONSE_DELAY_MS ?? 0);
  if (!Number.isFinite(delayMs) || delayMs <= 0) return;

  await new Promise((resolve) => setTimeout(resolve, delayMs));
}
