import type { ConfirmChannel, ConsumeMessage } from 'amqplib';
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

    await consumer.handleMessage(message, {
      ack,
      nack,
    } as unknown as ConfirmChannel);

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

  it('acknowledges a duplicate without repeating its effects', async () => {
    const sendOrderCreated = vi.fn();
    const publishNotificationSent = vi.fn().mockResolvedValue(undefined);
    const ack = vi.fn();
    const nack = vi.fn();
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);
    const channel = { ack, nack } as unknown as ConfirmChannel;

    await consumer.handleMessage(message, channel);
    await consumer.handleMessage(message, channel);

    expect(sendOrderCreated).toHaveBeenCalledOnce();
    expect(publishNotificationSent).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledTimes(2);
    expect(nack).not.toHaveBeenCalled();
  });

  it('schedules a retry when processing fails', async () => {
    const sendOrderCreated = vi.fn(() => {
      throw new Error('Notification failed');
    });
    const publishNotificationSent = vi.fn();
    const ack = vi.fn();
    const nack = vi.fn();
    const sendToQueue = vi.fn();
    const waitForConfirms = vi.fn().mockResolvedValue(undefined);
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);

    await consumer.handleMessage(message, {
      ack,
      nack,
      sendToQueue,
      waitForConfirms,
    } as unknown as ConfirmChannel);

    expect(publishNotificationSent).not.toHaveBeenCalled();
    expect(sendToQueue).toHaveBeenCalledWith(
      'notification.order-events.retry',
      message.content,
      expect.objectContaining({
        headers: { 'x-retry-count': 1 },
      }),
    );
    expect(waitForConfirms).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
  });

  it('does not acknowledge when notification.sent publication fails', async () => {
    const sendOrderCreated = vi.fn();
    const publishNotificationSent = vi
      .fn()
      .mockRejectedValue(new Error('Publish failed'));
    const ack = vi.fn();
    const nack = vi.fn();
    const sendToQueue = vi.fn();
    const waitForConfirms = vi.fn().mockResolvedValue(undefined);
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event);

    await consumer.handleMessage(message, {
      ack,
      nack,
      sendToQueue,
      waitForConfirms,
    } as unknown as ConfirmChannel);

    expect(sendOrderCreated).toHaveBeenCalledOnce();
    expect(publishNotificationSent).toHaveBeenCalledOnce();
    expect(sendToQueue).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
  });

  it('forwards the original message to the DLQ after retries are exhausted', async () => {
    const sendOrderCreated = vi.fn(() => {
      throw new Error('Notification failed');
    });
    const ack = vi.fn();
    const nack = vi.fn();
    const sendToQueue = vi.fn();
    const waitForConfirms = vi.fn().mockResolvedValue(undefined);
    const consumer = new RabbitMqConsumer(
      { sendOrderCreated } as unknown as NotificationService,
      { publishNotificationSent: vi.fn() } as unknown as RabbitMqPublisher,
    );
    const message = createMessage(event, { 'x-retry-count': 2 });

    await consumer.handleMessage(message, {
      ack,
      nack,
      sendToQueue,
      waitForConfirms,
    } as unknown as ConfirmChannel);

    expect(sendToQueue).toHaveBeenCalledWith(
      'notification.order-events.dlq',
      message.content,
      expect.objectContaining({
        headers: expect.objectContaining({
          'x-retry-count': 2,
          'x-failure-reason': 'Notification failed',
        }),
      }),
    );
    expect(waitForConfirms).toHaveBeenCalledOnce();
    expect(ack).toHaveBeenCalledWith(message);
    expect(nack).not.toHaveBeenCalled();
  });

  it('enables failure simulation only for the exact event in development', async () => {
    const previousNodeEnv = process.env.NODE_ENV;
    const previousFailureId = process.env.DEV_FAIL_EVENT_ID;
    process.env.NODE_ENV = 'development';
    process.env.DEV_FAIL_EVENT_ID = event.eventId;

    try {
      const sendOrderCreated = vi.fn();
      const sendToQueue = vi.fn();
      const ack = vi.fn();
      const consumer = new RabbitMqConsumer(
        { sendOrderCreated } as unknown as NotificationService,
        { publishNotificationSent: vi.fn() } as unknown as RabbitMqPublisher,
      );
      const message = createMessage(event);

      await consumer.handleMessage(message, {
        ack,
        nack: vi.fn(),
        sendToQueue,
        waitForConfirms: vi.fn().mockResolvedValue(undefined),
      } as unknown as ConfirmChannel);

      expect(sendOrderCreated).not.toHaveBeenCalled();
      expect(sendToQueue).toHaveBeenCalledWith(
        'notification.order-events.retry',
        message.content,
        expect.any(Object),
      );
      expect(ack).toHaveBeenCalledWith(message);
    } finally {
      restoreEnvironment('NODE_ENV', previousNodeEnv);
      restoreEnvironment('DEV_FAIL_EVENT_ID', previousFailureId);
    }
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
      type: eventType(payload),
      messageId: eventId(payload),
      correlationId: correlationId(payload),
    },
  } as ConsumeMessage;
}

function eventType(payload: object): string | undefined {
  return 'eventType' in payload && typeof payload.eventType === 'string'
    ? payload.eventType
    : undefined;
}

function eventId(payload: object): string | undefined {
  return 'eventId' in payload && typeof payload.eventId === 'string'
    ? payload.eventId
    : undefined;
}

function correlationId(payload: object): string | undefined {
  return 'correlationId' in payload && typeof payload.correlationId === 'string'
    ? payload.correlationId
    : undefined;
}

function restoreEnvironment(name: string, value: string | undefined): void {
  if (value === undefined) delete process.env[name];
  else process.env[name] = value;
}
