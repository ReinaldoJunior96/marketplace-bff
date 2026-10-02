import { Injectable } from '@nestjs/common';
import { AuditService } from '../../audit/audit.service.js';
import {
  MobileNotificationDto,
  type MobileOrderTimelineDto,
  MobileOrderTimelineStepDto,
} from './dto/mobile-activity.dto.js';

/**
 * Atividade assíncrona do marketplace vista pelo app: notificações e a linha
 * do tempo de cada pedido, montadas a partir dos eventos do Audit Service.
 */
@Injectable()
export class MobileActivityService {
  constructor(private readonly auditService: AuditService) {}

  async getNotifications(customerId: string): Promise<MobileNotificationDto[]> {
    const events =
      await this.auditService.findNotificationsForCustomer(customerId);

    return events
      .toSorted((a, b) => b.occurredAt.localeCompare(a.occurredAt))
      .map((event) => new MobileNotificationDto(event));
  }

  async getOrderTimeline(orderId: string): Promise<MobileOrderTimelineDto> {
    const events = await this.auditService.findEventsForOrder(orderId);

    return {
      orderId,
      steps: events
        .toSorted((a, b) => a.occurredAt.localeCompare(b.occurredAt))
        .map((event) => new MobileOrderTimelineStepDto(event)),
    };
  }
}
