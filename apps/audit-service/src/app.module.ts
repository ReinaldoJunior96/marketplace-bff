import { Module } from '@nestjs/common';
import { AuditService } from './audit/audit.service.js';
import { LogsController } from './audit/logs.controller.js';
import { HealthController } from './health.controller.js';
import { RabbitMqConsumer } from './messaging/rabbitmq.consumer.js';

@Module({
  imports: [],
  controllers: [HealthController, LogsController],
  providers: [AuditService, RabbitMqConsumer],
})
export class AppModule {}
