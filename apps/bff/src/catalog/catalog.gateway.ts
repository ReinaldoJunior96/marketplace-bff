import { Injectable, NotFoundException } from '@nestjs/common';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import { DownstreamHttpClient } from '../common/downstream-http.client.js';
import type { Product } from './product.js';

@Injectable()
export class CatalogGateway {
  private readonly baseUrl: string;

  constructor(private readonly http: DownstreamHttpClient) {
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
      response = await this.http.request(
        'catalog-service',
        `${this.baseUrl}${path}`,
        undefined,
        { retryable: true },
      );
    } catch (error) {
      if (error instanceof DownstreamServiceUnavailableException) throw error;
      throw new DownstreamServiceUnavailableException('catalog-service');
    }

    if (response.status === 404) {
      throw new NotFoundException('Product not found');
    }

    if (!response.ok) {
      throw new DownstreamServiceUnavailableException('catalog-service');
    }

    return (await response.json()) as T;
  }
}
