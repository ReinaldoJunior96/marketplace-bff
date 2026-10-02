import { Injectable, Logger } from '@nestjs/common';
import type { MarketplaceEvent } from '../events/marketplace-event.js';
import type { AuditEvent } from './audit-event.js';

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);
  private readonly events: AuditEvent[] = [];

  store(event: MarketplaceEvent): AuditEvent {
    const auditEvent: AuditEvent = {
      eventId: event.eventId,
      eventType: event.eventType,
      correlationId: event.correlationId,
      occurredAt: event.occurredAt,
      consumedAt: new Date().toISOString(),
      payload: event.data,
    };

    this.events.push(auditEvent);
    this.logger.log({
      eventType: auditEvent.eventType,
      eventId: auditEvent.eventId,
      correlationId: auditEvent.correlationId,
      message: 'Audit event stored',
    });

    return auditEvent;
  }

  findAll(): AuditEvent[] {
    return [...this.events];
  }

  findByCorrelationId(correlationId: string): AuditEvent[] {
    return this.events.filter(
      (event) => event.correlationId === correlationId,
    );
  }
}
