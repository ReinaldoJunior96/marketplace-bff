import type { AuditEvent } from '../../audit/audit-event.js';
import type { AuditService } from '../../audit/audit.service.js';
import { MobileActivityService } from './mobile-activity.service.js';

describe('MobileActivityService', () => {
  const orderCreated: AuditEvent = {
    eventId: 'event-1',
    eventType: 'order.created',
    correlationId: 'correlation-1',
    occurredAt: '2026-10-02T12:00:00.000Z',
    consumedAt: '2026-10-02T12:00:00.200Z',
    payload: { orderId: 'a1b2c3d4-0000', customerId: 'customer-1' },
  };
  const notificationSent: AuditEvent = {
    eventId: 'event-2',
    eventType: 'notification.sent',
    correlationId: 'correlation-1',
    occurredAt: '2026-10-02T12:00:01.000Z',
    consumedAt: '2026-10-02T12:00:01.100Z',
    payload: { orderId: 'a1b2c3d4-0000', customerId: 'customer-1' },
  };

  it('maps notifications for mobile, newest first', async () => {
    const older = {
      ...notificationSent,
      eventId: 'event-0',
      occurredAt: '2026-10-01T09:00:00.000Z',
    };
    const auditService = {
      findNotificationsForCustomer: vi
        .fn()
        .mockResolvedValue([older, notificationSent]),
    } as unknown as AuditService;

    const notifications = await new MobileActivityService(
      auditService,
    ).getNotifications('customer-1');

    expect(notifications.map((n) => n.id)).toEqual(['event-2', 'event-0']);
    expect(notifications[0]).toEqual({
      id: 'event-2',
      orderId: 'a1b2c3d4-0000',
      title: 'Pedido confirmado',
      message: 'Seu pedido #a1b2c3d4 foi recebido e já está sendo preparado.',
      sentAt: '2026-10-02T12:00:01.000Z',
    });
  });

  it('builds the order timeline in chronological order with the source service', async () => {
    const auditService = {
      findEventsForOrder: vi
        .fn()
        .mockResolvedValue([notificationSent, orderCreated]),
    } as unknown as AuditService;

    await expect(
      new MobileActivityService(auditService).getOrderTimeline('a1b2c3d4-0000'),
    ).resolves.toEqual({
      orderId: 'a1b2c3d4-0000',
      steps: [
        {
          event: 'order.created',
          service: 'order-service',
          occurredAt: orderCreated.occurredAt,
          auditedAt: orderCreated.consumedAt,
        },
        {
          event: 'notification.sent',
          service: 'notification-service',
          occurredAt: notificationSent.occurredAt,
          auditedAt: notificationSent.consumedAt,
        },
      ],
    });
  });
});
