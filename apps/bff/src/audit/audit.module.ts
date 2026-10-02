import { Module } from '@nestjs/common';
import { AuditGateway } from './audit.gateway.js';
import { AuditService } from './audit.service.js';

@Module({
  providers: [AuditService, AuditGateway],
  exports: [AuditService],
})
export class AuditModule {}
