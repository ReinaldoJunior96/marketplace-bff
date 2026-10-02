import type { CatalogService } from '../../catalog/catalog.service.js';
import type { Product } from '../../catalog/product.js';
import { MobileHomeService } from './mobile-home.service.js';

describe('MobileHomeService', () => {
  it('returns only the fields needed by mobile', async () => {
    const product: Product = {
      id: 'product-001',
      name: 'Teclado Mecânico',
      description: 'Teclado mecânico compacto.',
      price: 399.9,
      image: 'https://example.com/product-001.png',
      category: 'Periféricos',
      stock: 10,
    };
    const catalogService = {
      findAll: vi.fn().mockResolvedValue([product]),
    } as unknown as CatalogService;
    const service = new MobileHomeService(catalogService);

    await expect(service.getHome()).resolves.toEqual({
      products: [
        {
          id: product.id,
          name: product.name,
          price: product.price,
          thumbnail: product.image,
        },
      ],
    });
  });
});
