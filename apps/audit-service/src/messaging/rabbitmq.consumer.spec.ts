import type { Channel, ConsumeMessage } from 'amqplib';
import type { AuditService } from '../audit/audit.service.js';
import { RabbitMqConsumer } from './rabbitmq.consumer.js';

describe('RabbitMqConsumer', () => {
  const event = {
    eventId: 'event-123',
    eventType: 'order.created',
    occurredAt: '2026-10-01T19:00:00.000Z',
    correlationId: 'audit-test-001',
    data: { orderId: 'order-123' },
  };

  it('acknowledges only after storing the audit event', async () => {
    const store = vi.fn();
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer({
      store,
    } as unknown as AuditService);
    const message = createMessage(event);

    await consumer.handleMessage(message, { ack, nack } as unknown as Channel);

    expect(store).toHaveBeenCalledWith(event);
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
    expect(store.mock.invocationCallOrder[0]).toBeLessThan(
      ack.mock.invocationCallOrder[0],
    );
  });

  it('acknowledges a duplicate without storing it again', async () => {
    const store = vi.fn();
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer({ store } as unknown as AuditService);
    const message = createMessage(event);
    const channel = { ack, nack } as unknown as Channel;

    await consumer.handleMessage(message, channel);
    await consumer.handleMessage(message, channel);

    expect(store).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledTimes(2);
    expect(nack).not.toHaveBeenCalled();
  });

  it('rejects without requeue when storage fails', async () => {
    const store = vi.fn(() => {
      throw new Error('Storage failed');
    });
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer({
      store,
    } as unknown as AuditService);
    const message = createMessage(event);

    await consumer.handleMessage(message, { ack, nack } as unknown as Channel);

    expect(ack).not.toHaveBeenCalled();
    expect(nack).toHaveBeenCalledWith(message, false, false);
  });
});

function createMessage(payload: object): ConsumeMessage {
  return {
    content: Buffer.from(JSON.stringify(payload)),
  } as ConsumeMessage;
}
