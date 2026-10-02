import { Injectable } from '@nestjs/common';
import { CatalogService } from '../../catalog/catalog.service.js';
import {
  type MobileHomeDto,
  MobileProductDto,
} from './dto/mobile-product.dto.js';

@Injectable()
export class MobileHomeService {
  constructor(private readonly catalogService: CatalogService) {}

  async getHome(): Promise<MobileHomeDto> {
    const products = await this.catalogService.findAll();

    return {
      products: products.map((product) => new MobileProductDto(product)),
    };
  }
}
