import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { AppModule } from '../src/app.module.js';
import { RabbitMqPublisher } from '../src/messaging/rabbitmq.publisher.js';

describe('Order Service (e2e)', () => {
  let app: NestFastifyApplication;
  const publishOrderCreated = vi.fn().mockResolvedValue(undefined);

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(RabbitMqPublisher)
      .useValue({ publishOrderCreated })
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

  it('reports its health', async () => {
    const response = await app.inject({ method: 'GET', url: '/health' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: 'ok' });
  });

  it('creates and retrieves an order', async () => {
    const createResponse = await app.inject({
      method: 'POST',
      url: '/orders',
      headers: { 'x-correlation-id': 'correlation-123' },
      payload: {
        customerId: 'customer-123',
        items: [{ productId: 'product-123', quantity: 2 }],
      },
    });
    const created = createResponse.json();

    expect(createResponse.statusCode).toBe(201);
    expect(created.status).toBe('CREATED');
    expect(publishOrderCreated).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'order.created',
        correlationId: 'correlation-123',
        data: expect.objectContaining({ orderId: created.id }),
      }),
    );

    const getResponse = await app.inject({
      method: 'GET',
      url: `/orders/${created.id}`,
    });

    expect(getResponse.statusCode).toBe(200);
    expect(getResponse.json()).toEqual(created);
  });

  it('generates a correlation ID when the header is absent', async () => {
    await app.inject({
      method: 'POST',
      url: '/orders',
      payload: {
        customerId: 'customer-456',
        items: [{ productId: 'product-456', quantity: 1 }],
      },
    });

    expect(publishOrderCreated).toHaveBeenLastCalledWith(
      expect.objectContaining({
        correlationId: expect.stringMatching(
          /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
        ),
      }),
    );
  });
});
