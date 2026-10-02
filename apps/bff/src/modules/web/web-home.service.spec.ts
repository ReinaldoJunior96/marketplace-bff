import type { CatalogService } from '../../catalog/catalog.service.js';
import type { Product } from '../../catalog/product.js';
import { WebHomeService } from './web-home.service.js';

describe('WebHomeService', () => {
  it('returns the complete product representation for web', async () => {
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
    const service = new WebHomeService(catalogService);

    await expect(service.getHome()).resolves.toEqual({
      featuredProducts: [product],
    });
  });
});
