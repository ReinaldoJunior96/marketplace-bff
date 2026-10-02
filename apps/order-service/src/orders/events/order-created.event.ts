import type { OrderItem } from '../order.js';

export const ORDER_CREATED_EVENT = 'order.created' as const;

export interface OrderCreatedEvent {
  eventId: string;
  eventType: typeof ORDER_CREATED_EVENT;
  occurredAt: string;
  correlationId: string;
  data: {
    orderId: string;
    customerId: string;
    items: OrderItem[];
    status: 'CREATED';
  };
}
