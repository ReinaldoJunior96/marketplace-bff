import { Injectable, NotFoundException } from '@nestjs/common';
import type { Product } from './product.js';
import { PRODUCTS } from './products.data.js';

@Injectable()
export class ProductsService {
  private readonly products = PRODUCTS;

  findAll(): Product[] {
    return this.products;
  }

  findById(id: string): Product {
    const product = this.products.find((item) => item.id === id);

    if (!product) {
      throw new NotFoundException(`Product ${id} not found`);
    }

    return product;
  }
}
