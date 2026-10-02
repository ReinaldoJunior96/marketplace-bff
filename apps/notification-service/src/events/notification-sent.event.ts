import { randomUUID } from 'node:crypto';
import type { OrderCreatedEvent } from './order-created.event.js';

export const NOTIFICATION_SENT_EVENT = 'notification.sent' as const;

export interface NotificationSentEvent {
  eventId: string;
  eventType: typeof NOTIFICATION_SENT_EVENT;
  occurredAt: string;
  correlationId: string;
  data: {
    orderId: string;
    customerId: string;
    channel: 'mock';
    status: 'SENT';
  };
}

export function createNotificationSentEvent(
  orderCreated: OrderCreatedEvent,
): NotificationSentEvent {
  return {
    eventId: randomUUID(),
    eventType: NOTIFICATION_SENT_EVENT,
    occurredAt: new Date().toISOString(),
    correlationId: orderCreated.correlationId,
    data: {
      orderId: orderCreated.data.orderId,
      customerId: orderCreated.data.customerId,
      channel: 'mock',
      status: 'SENT',
    },
  };
}
