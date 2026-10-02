import type { Channel, ConsumeMessage } from 'amqplib';
import type { NotificationService } from '../notifications/notification.service.js';
import { RabbitMqConsumer } from './rabbitmq.consumer.js';
import type { RabbitMqPublisher } from './rabbitmq.publisher.js';

describe('RabbitMqConsumer', () => {
  const event = {
    eventId: 'event-123',
    eventType: 'order.created',
    occurredAt: '2026-10-01T18:00:00.000Z',
    correlationId: 'correlation-123',
    data: {
      orderId: 'order-123',
      customerId: 'customer-123',
      items: [{ productId: 'product-123', quantity: 2 }],
      status: 'CREATED',
    },
  };

  it('publishes notification.sent and acknowledges only after confirmation', async () => {
    const sendOrderCreated = vi.fn();
    const publishNotificationSent = vi.fn().mockResolvedValue(undefined);
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);

    await consumer.handleMessage(message, { ack, nack } as unknown as Channel);

    expect(sendOrderCreated).toHaveBeenCalledOnce();
    expect(publishNotificationSent).toHaveBeenCalledOnce();
    expect(publishNotificationSent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'notification.sent',
        correlationId: event.correlationId,
        data: {
          orderId: event.data.orderId,
          customerId: event.data.customerId,
          channel: 'mock',
          status: 'SENT',
        },
      }),
    );
    const publishedEvent = publishNotificationSent.mock.calls[0][0];
    expect(publishedEvent.eventId).not.toBe(event.eventId);
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
    expect(sendOrderCreated.mock.invocationCallOrder[0]).toBeLessThan(
      publishNotificationSent.mock.invocationCallOrder[0],
    );
    expect(publishNotificationSent.mock.invocationCallOrder[0]).toBeLessThan(
      ack.mock.invocationCallOrder[0],
    );
  });

  it('rejects without requeue when processing fails', async () => {
    const sendOrderCreated = vi.fn(() => {
      throw new Error('Notification failed');
    });
    const publishNotificationSent = vi.fn();
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);

    await consumer.handleMessage(message, { ack, nack } as unknown as Channel);

    expect(publishNotificationSent).not.toHaveBeenCalled();
    expect(ack).not.toHaveBeenCalled();
    expect(nack).toHaveBeenCalledWith(message, false, false);
  });

  it('does not acknowledge when notification.sent publication fails', async () => {
    const sendOrderCreated = vi.fn();
    const publishNotificationSent = vi
      .fn()
      .mockRejectedValue(new Error('Publish failed'));
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);

    await consumer.handleMessage(message, { ack, nack } as unknown as Channel);

    expect(sendOrderCreated).toHaveBeenCalledOnce();
    expect(publishNotificationSent).toHaveBeenCalledOnce();
    expect(ack).not.toHaveBeenCalled();
    expect(nack).toHaveBeenCalledWith(message, false, false);
  });
});

function createMessage(payload: object): ConsumeMessage {
  return {
    content: Buffer.from(JSON.stringify(payload)),
  } as ConsumeMessage;
}
