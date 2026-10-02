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

export class MobileProductDetailDto {
  id: string;
  name: string;
  description: string;
  price: number;
  image: string;
  category: string;
  stock: number;

  constructor(product: Product) {
    this.id = product.id;
    this.name = product.name;
    this.description = product.description;
    this.price = product.price;
    this.image = product.image;
    this.category = product.category;
    this.stock = product.stock;
  }
}
