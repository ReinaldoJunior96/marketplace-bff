import { Controller, Get, Param } from '@nestjs/common';
import type { AuditEvent } from './audit-event.js';
import { AuditService } from './audit.service.js';

@Controller('logs')
export class LogsController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  findAll(): AuditEvent[] {
    return this.auditService.findAll();
  }

  @Get(':correlationId')
  findByCorrelationId(
    @Param('correlationId') correlationId: string,
  ): AuditEvent[] {
    return this.auditService.findByCorrelationId(correlationId);
  }
}
