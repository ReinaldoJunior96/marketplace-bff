import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import type { MobileNotificationDto } from './dto/mobile-activity.dto.js';
import { MobileActivityService } from './mobile-activity.service.js';

@Controller('api/mobile/notifications')
export class MobileNotificationsController {
  constructor(private readonly activityService: MobileActivityService) {}

  @Get()
  findAll(
    @Query('customerId') customerId: string | undefined,
  ): Promise<MobileNotificationDto[]> {
    if (!customerId?.trim()) {
      throw new BadRequestException('customerId is required');
    }

    return this.activityService.getNotifications(customerId.trim());
  }
}
