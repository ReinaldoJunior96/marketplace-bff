export interface AuditEvent {
  eventId: string;
  eventType: string;
  correlationId: string;
  occurredAt: string;
  consumedAt: string;
  payload: unknown;
}
