import { NotFoundException } from '@nestjs/common';
import { ProductsService } from './products.service.js';

describe('ProductsService', () => {
  const service = new ProductsService();

  it('returns the initial catalog', () => {
    expect(service.findAll()).toHaveLength(8);
  });

  it('returns a product by ID', () => {
    expect(service.findById('product-001')).toEqual(
      expect.objectContaining({
        id: 'product-001',
        name: 'Teclado Mecânico',
      }),
    );
  });

  it('throws when a product does not exist', () => {
    expect(() => service.findById('product-999')).toThrow(NotFoundException);
  });
});
