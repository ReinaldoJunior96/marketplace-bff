import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { AppModule } from '../src/app.module.js';
import { CatalogGateway } from '../src/catalog/catalog.gateway.js';

describe('AppController (e2e)', () => {
  let app: NestFastifyApplication;
  const product = {
    id: 'product-001',
    name: 'Teclado Mecânico',
    description: 'Teclado mecânico compacto.',
    price: 399.9,
    image: 'https://example.com/product-001.png',
    category: 'Periféricos',
    stock: 10,
  };

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(CatalogGateway)
      .useValue({
        findAll: vi.fn().mockResolvedValue([product]),
        findById: vi.fn().mockResolvedValue(product),
      })
      .compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('serves the initial endpoint', async () => {
    const response = await app.inject({ method: 'GET', url: '/' });

    expect(response.statusCode).toBe(200);
    expect(response.body).toBe('Hello World!');
  });

  it('lists products through the catalog integration', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/catalog/products',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual([product]);
  });

  it('gets a product through the catalog integration', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/catalog/products/product-001',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual(product);
  });

  it('returns the web home contract', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/web/home',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ featuredProducts: [product] });
  });

  it('returns the reduced mobile home contract', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/mobile/home',
    });
    const body = response.json();

    expect(response.statusCode).toBe(200);
    expect(body).toEqual({
      products: [
        {
          id: product.id,
          name: product.name,
          price: product.price,
          thumbnail: product.image,
        },
      ],
    });
    expect(body.products[0]).not.toHaveProperty('description');
    expect(body.products[0]).not.toHaveProperty('stock');
    expect(body.products[0]).not.toHaveProperty('category');
  });
});
