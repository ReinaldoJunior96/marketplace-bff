import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { AppModule } from '../src/app.module.js';
import { AuditService } from '../src/audit/audit.service.js';
import { RabbitMqConsumer } from '../src/messaging/rabbitmq.consumer.js';

describe('Audit Service (e2e)', () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(RabbitMqConsumer)
      .useValue({})
      .compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    moduleFixture.get(AuditService).store({
      eventId: 'event-123',
      eventType: 'order.created',
      correlationId: 'audit-test-001',
      occurredAt: '2026-10-01T19:00:00.000Z',
      data: { orderId: 'order-123' },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('reports its health', async () => {
    const response = await app.inject({ method: 'GET', url: '/health' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: 'ok' });
  });

  it('returns all audit events', async () => {
    const response = await app.inject({ method: 'GET', url: '/logs' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual([
      expect.objectContaining({
        eventType: 'order.created',
        correlationId: 'audit-test-001',
      }),
    ]);
  });

  it('filters audit events by correlation ID', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/logs/audit-test-001',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toHaveLength(1);
    expect(response.json()[0].correlationId).toBe('audit-test-001');
  });
});
