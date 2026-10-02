import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { AppModule } from '../src/app.module.js';
import { CatalogGateway } from '../src/catalog/catalog.gateway.js';
import { DownstreamServiceUnavailableException } from '../src/common/downstream-service.exception.js';
import { OrdersGateway } from '../src/orders/orders.gateway.js';

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
  const order = {
    id: 'order-001',
    customerId: 'customer-123',
    items: [{ productId: 'product-001', quantity: 1 }],
    status: 'CREATED' as const,
    createdAt: '2026-10-02T12:00:00.000Z',
  };
  const findAllProducts = vi.fn().mockResolvedValue([product]);
  const createOrder = vi.fn().mockResolvedValue(order);
  const findAllOrders = vi.fn().mockResolvedValue([order]);

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(CatalogGateway)
      .useValue({
        findAll: findAllProducts,
        findById: vi.fn().mockResolvedValue(product),
      })
      .overrideProvider(OrdersGateway)
      .useValue({ create: createOrder, findAll: findAllOrders })
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

  it('standardizes downstream failures without leaking details', async () => {
    findAllProducts.mockRejectedValueOnce(
      new DownstreamServiceUnavailableException('catalog-service'),
    );

    const response = await app.inject({
      method: 'GET',
      url: '/api/web/home',
      headers: { 'x-correlation-id': 'failure-test-001' },
    });

    expect(response.statusCode).toBe(503);
    expect(response.headers['x-correlation-id']).toBe('failure-test-001');
    expect(response.json()).toEqual({
      statusCode: 503,
      error: 'Service Unavailable',
      message: 'Catalog service is unavailable',
      correlationId: 'failure-test-001',
    });
    expect(response.body).not.toContain('ECONNREFUSED');
    expect(response.body).not.toContain('catalog-service');
    expect(response.body).not.toContain('stack');
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

  it.each(['web', 'mobile'])(
    'creates an order through the %s client API',
    async (client) => {
      const payload = {
        customerId: 'customer-123',
        items: [{ productId: 'product-001', quantity: 1 }],
      };
      const response = await app.inject({
        method: 'POST',
        url: `/api/${client}/orders`,
        headers: { 'x-correlation-id': 'front-test-001' },
        payload,
      });

      expect(response.statusCode).toBe(201);
      expect(response.headers['x-correlation-id']).toBe('front-test-001');
      expect(response.json()).toEqual(order);
      expect(createOrder).toHaveBeenCalledWith(payload, 'front-test-001');
    },
  );

  it('returns the complete order view for web', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/web/orders',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual([order]);
  });

  it('returns the reduced order view for mobile', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/mobile/orders',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual([
      {
        id: order.id,
        status: order.status,
        itemsCount: order.items.length,
        createdAt: order.createdAt,
      },
    ]);
    expect(response.json()[0]).not.toHaveProperty('customerId');
    expect(response.json()[0]).not.toHaveProperty('items');
  });

  it('generates and returns a correlation ID when one is not provided', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/web/orders',
      payload: {
        customerId: 'customer-123',
        items: [{ productId: 'product-001', quantity: 1 }],
      },
    });

    const correlationId = response.headers['x-correlation-id'];

    expect(response.statusCode).toBe(201);
    expect(correlationId).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    expect(createOrder).toHaveBeenLastCalledWith(
      expect.any(Object),
      correlationId,
    );
  });

  it('rejects an invalid order before calling the Order Service', async () => {
    createOrder.mockClear();

    const response = await app.inject({
      method: 'POST',
      url: '/api/mobile/orders',
      payload: {
        customerId: 'customer-123',
        items: [{ productId: 'product-001', quantity: 0 }],
      },
    });

    expect(response.statusCode).toBe(400);
    expect(createOrder).not.toHaveBeenCalled();
  });
});
