import { Injectable } from '@nestjs/common';
import { DownstreamFallbackService } from '../common/downstream-fallback.service.js';
import type { AuditEvent } from './audit-event.js';
import { AuditGateway } from './audit.gateway.js';

export const NOTIFICATION_SENT_EVENT = 'notification.sent';

/**
 * Consulta os eventos registrados pelo Audit Service.
 *
 * O Audit é uma dependência opcional: se estiver indisponível, as consultas
 * degradam para uma lista vazia em vez de falhar a requisição do cliente.
 */
@Injectable()
export class AuditService {
  constructor(
    private readonly auditGateway: AuditGateway,
    private readonly fallbacks: DownstreamFallbackService,
  ) {}

  async findNotificationsForCustomer(
    customerId: string,
  ): Promise<AuditEvent[]> {
    const events = await this.findAllOrEmpty();
    return events.filter(
      (event) =>
        event.eventType === NOTIFICATION_SENT_EVENT &&
        payloadField(event, 'customerId') === customerId,
    );
  }

  async findEventsForOrder(orderId: string): Promise<AuditEvent[]> {
    const events = await this.findAllOrEmpty();
    return events.filter((event) => payloadField(event, 'orderId') === orderId);
  }

  private findAllOrEmpty(): Promise<AuditEvent[]> {
    return this.fallbacks.execute({
      service: 'audit-service',
      operation: () => this.auditGateway.findAll(),
      fallback: () => [],
    });
  }
}

export function payloadField(event: AuditEvent, field: string): unknown {
  const payload = event.payload;
  if (typeof payload !== 'object' || payload === null) return undefined;
  return (payload as Record<string, unknown>)[field];
}
