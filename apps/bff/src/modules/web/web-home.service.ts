import { Injectable } from '@nestjs/common';
import { CatalogService } from '../../catalog/catalog.service.js';
import { WebProductDto, type WebHomeDto } from './dto/web-product.dto.js';

@Injectable()
export class WebHomeService {
  constructor(private readonly catalogService: CatalogService) {}

  async getHome(): Promise<WebHomeDto> {
    const products = await this.catalogService.findAll();

    return {
      featuredProducts: products.map((product) => new WebProductDto(product)),
    };
  }
}
