import { Injectable, Logger } from '@nestjs/common';
import type { OrderCreatedEvent } from '../events/order-created.event.js';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  sendOrderCreated(event: OrderCreatedEvent): void {
    this.logger.log({
      eventType: event.eventType,
      eventId: event.eventId,
      orderId: event.data.orderId,
      customerId: event.data.customerId,
      correlationId: event.correlationId,
      message: `Notification processed for order ${event.data.orderId}`,
    });
  }
}
