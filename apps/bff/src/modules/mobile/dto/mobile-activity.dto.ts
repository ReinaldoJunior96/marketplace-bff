import type { AuditEvent } from '../../../audit/audit-event.js';
import { payloadField } from '../../../audit/audit.service.js';

/** Serviço que originou cada evento conhecido do marketplace. */
const EVENT_SOURCES: Record<string, string> = {
  'order.created': 'order-service',
  'notification.sent': 'notification-service',
};

export class MobileNotificationDto {
  id: string;
  orderId: string;
  title: string;
  message: string;
  sentAt: string;

  constructor(event: AuditEvent) {
    const rawOrderId = payloadField(event, 'orderId');
    const orderId = typeof rawOrderId === 'string' ? rawOrderId : '';
    this.id = event.eventId;
    this.orderId = orderId;
    this.title = 'Pedido confirmado';
    this.message = `Seu pedido #${orderId.slice(0, 8)} foi recebido e já está sendo preparado.`;
    this.sentAt = event.occurredAt;
  }
}

export class MobileOrderTimelineStepDto {
  event: string;
  service: string;
  occurredAt: string;
  auditedAt: string;

  constructor(event: AuditEvent) {
    this.event = event.eventType;
    this.service = EVENT_SOURCES[event.eventType] ?? 'unknown';
    this.occurredAt = event.occurredAt;
    this.auditedAt = event.consumedAt;
  }
}

export interface MobileOrderTimelineDto {
  orderId: string;
  steps: MobileOrderTimelineStepDto[];
}
