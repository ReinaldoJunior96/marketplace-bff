import type { ConfirmChannel, ConsumeMessage } from 'amqplib';
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

    await consumer.handleMessage(message, {
      ack,
      nack,
    } as unknown as ConfirmChannel);

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
    const channel = { ack, nack } as unknown as ConfirmChannel;

    await consumer.handleMessage(message, channel);
    await consumer.handleMessage(message, channel);

    expect(store).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledTimes(2);
    expect(nack).not.toHaveBeenCalled();
  });

  it('schedules a retry when storage fails', async () => {
    const store = vi.fn(() => {
      throw new Error('Storage failed');
    });
    const ack = vi.fn();
    const nack = vi.fn();
    const sendToQueue = vi.fn();
    const waitForConfirms = vi.fn().mockResolvedValue(undefined);
    const consumer = new RabbitMqConsumer({
      store,
    } as unknown as AuditService);
    const message = createMessage(event);

    await consumer.handleMessage(message, {
      ack,
      nack,
      sendToQueue,
      waitForConfirms,
    } as unknown as ConfirmChannel);

    expect(sendToQueue).toHaveBeenCalledWith(
      'audit.marketplace-events.retry',
      message.content,
      expect.objectContaining({ headers: { 'x-retry-count': 1 } }),
    );
    expect(waitForConfirms).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
  });

  it('rejects after the retry limit is exhausted', async () => {
    const store = vi.fn(() => {
      throw new Error('Storage failed');
    });
    const ack = vi.fn();
    const nack = vi.fn();
    const sendToQueue = vi.fn();
    const consumer = new RabbitMqConsumer({ store } as unknown as AuditService);
    const message = createMessage(event, { 'x-retry-count': 2 });

    await consumer.handleMessage(message, {
      ack,
      nack,
      sendToQueue,
    } as unknown as ConfirmChannel);

    expect(sendToQueue).not.toHaveBeenCalled();
    expect(ack).not.toHaveBeenCalled();
    expect(nack).toHaveBeenCalledWith(message, false, false);
  });
});

function createMessage(
  payload: object,
  headers: Record<string, unknown> = {},
): ConsumeMessage {
  return {
    content: Buffer.from(JSON.stringify(payload)),
    properties: {
      headers,
      contentType: 'application/json',
      type:
        'eventType' in payload && typeof payload.eventType === 'string'
          ? payload.eventType
          : undefined,
      messageId:
        'eventId' in payload && typeof payload.eventId === 'string'
          ? payload.eventId
          : undefined,
      correlationId:
        'correlationId' in payload && typeof payload.correlationId === 'string'
          ? payload.correlationId
          : undefined,
    },
  } as ConsumeMessage;
}
