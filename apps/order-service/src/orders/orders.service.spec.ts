import { NotFoundException } from '@nestjs/common';
import type { RabbitMqPublisher } from '../messaging/rabbitmq.publisher.js';
import { OrdersService } from './orders.service.js';

describe('OrdersService', () => {
  const input = {
    customerId: 'customer-123',
    items: [{ productId: 'product-123', quantity: 2 }],
  };

  const publishOrderCreated = vi.fn().mockResolvedValue(undefined);
  const publisher = { publishOrderCreated } as unknown as RabbitMqPublisher;

  beforeEach(() => {
    publishOrderCreated.mockClear();
  });

  it('creates, publishes and retrieves an order', async () => {
    const service = new OrdersService(publisher);

    const created = await service.create(input, 'correlation-123');
    const retrieved = service.findById(created.id);

    expect(created.id).toBeDefined();
    expect(created.status).toBe('CREATED');
    expect(created.createdAt).toBeDefined();
    expect(retrieved).toEqual(created);
    expect(service.findAll()).toEqual([created]);
    expect(publishOrderCreated).toHaveBeenCalledWith({
      eventId: expect.any(String),
      eventType: 'order.created',
      occurredAt: expect.any(String),
      correlationId: 'correlation-123',
      data: {
        orderId: created.id,
        customerId: created.customerId,
        items: created.items,
        status: 'CREATED',
      },
    });
  });

  it('rejects an unknown order', () => {
    const service = new OrdersService(publisher);

    expect(() => service.findById('unknown')).toThrow(NotFoundException);
  });

  it('keeps the order in memory when publication fails', async () => {
    const service = new OrdersService(publisher);
    publishOrderCreated.mockRejectedValueOnce(new Error('RabbitMQ unavailable'));

    await expect(service.create(input, 'correlation-456')).rejects.toThrow(
      'RabbitMQ unavailable',
    );

    const publishedEvent = publishOrderCreated.mock.calls[0][0];
    expect(service.findById(publishedEvent.data.orderId)).toBeDefined();
  });
});
