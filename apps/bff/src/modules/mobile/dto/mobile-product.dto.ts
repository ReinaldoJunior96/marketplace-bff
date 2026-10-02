import type { Product } from '../../../catalog/product.js';

export class MobileProductDto {
  id: string;
  name: string;
  price: number;
  thumbnail: string;

  constructor(product: Product) {
    this.id = product.id;
    this.name = product.name;
    this.price = product.price;
    this.thumbnail = product.image;
  }
}

export interface MobileHomeDto {
  products: MobileProductDto[];
}
