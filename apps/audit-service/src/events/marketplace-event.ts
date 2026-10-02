export interface MarketplaceEvent {
  eventId: string;
  eventType: string;
  correlationId: string;
  occurredAt: string;
  data: unknown;
}
