import { Injectable } from '@nestjs/common';
import { CatalogGateway } from './catalog.gateway.js';
import type { Product } from './product.js';

@Injectable()
export class CatalogService {
  constructor(private readonly catalogGateway: CatalogGateway) {}

  findAll(): Promise<Product[]> {
    return this.catalogGateway.findAll();
  }

  findById(id: string): Promise<Product> {
    return this.catalogGateway.findById(id);
  }
}
