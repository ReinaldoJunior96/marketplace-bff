import { CorrelationIdService } from '../common/correlation-id.service.js';
import { DownstreamFallbackService } from '../common/downstream-fallback.service.js';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import type { AuditEvent } from './audit-event.js';
import type { AuditGateway } from './audit.gateway.js';
import { AuditService } from './audit.service.js';

describe('AuditService', () => {
  const event = (
    eventType: string,
    payload: Record<string, unknown>,
  ): AuditEvent => ({
    eventId: `${eventType}-${String(payload.orderId)}`,
    eventType,
    correlationId: 'correlation-1',
    occurredAt: '2026-10-02T12:00:00.000Z',
    consumedAt: '2026-10-02T12:00:01.000Z',
    payload,
  });

  const events = [
    event('order.created', { orderId: 'order-1', customerId: 'customer-1' }),
    event('notification.sent', {
      orderId: 'order-1',
      customerId: 'customer-1',
    }),
    event('notification.sent', {
      orderId: 'order-2',
      customerId: 'customer-2',
    }),
  ];

  const createService = (findAll: AuditGateway['findAll']) =>
    new AuditService(
      { findAll } as AuditGateway,
      new DownstreamFallbackService(new CorrelationIdService()),
    );

  it('returns only notifications sent to the customer', async () => {
    const service = createService(vi.fn().mockResolvedValue(events));

    await expect(
      service.findNotificationsForCustomer('customer-1'),
    ).resolves.toEqual([events[1]]);
  });

  it('returns every event of an order', async () => {
    const service = createService(vi.fn().mockResolvedValue(events));

    await expect(service.findEventsForOrder('order-1')).resolves.toEqual([
      events[0],
      events[1],
    ]);
  });

  it('degrades to an empty list when the Audit Service is unavailable', async () => {
    const service = createService(
      vi
        .fn()
        .mockRejectedValue(
          new DownstreamServiceUnavailableException('audit-service'),
        ),
    );

    await expect(
      service.findNotificationsForCustomer('customer-1'),
    ).resolves.toEqual([]);
    await expect(service.findEventsForOrder('order-1')).resolves.toEqual([]);
  });
});
