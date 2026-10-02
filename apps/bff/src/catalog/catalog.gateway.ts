import { Injectable, NotFoundException } from '@nestjs/common';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import type { Product } from './product.js';

@Injectable()
export class CatalogGateway {
  private readonly baseUrl: string;

  constructor() {
    const url = process.env.CATALOG_SERVICE_URL;

    if (!url) {
      throw new Error('CATALOG_SERVICE_URL is required');
    }

    this.baseUrl = url.replace(/\/$/, '');
  }

  findAll(): Promise<Product[]> {
    return this.request<Product[]>('/products');
  }

  findById(id: string): Promise<Product> {
    return this.request<Product>(`/products/${encodeURIComponent(id)}`);
  }

  private async request<T>(path: string): Promise<T> {
    let response: Response;

    try {
      response = await fetch(`${this.baseUrl}${path}`);
    } catch {
      throw new DownstreamServiceUnavailableException('Catalog');
    }

    if (response.status === 404) {
      throw new NotFoundException('Product not found');
    }

    if (!response.ok) {
      throw new DownstreamServiceUnavailableException('Catalog');
    }

    return (await response.json()) as T;
  }
}
