import { Module } from '@nestjs/common';
import { HealthController } from './health.controller.js';
import { RabbitMqConsumer } from './messaging/rabbitmq.consumer.js';
import { RabbitMqPublisher } from './messaging/rabbitmq.publisher.js';
import { NotificationService } from './notifications/notification.service.js';

@Module({
  imports: [],
  controllers: [HealthController],
  providers: [NotificationService, RabbitMqPublisher, RabbitMqConsumer],
})
export class AppModule {}
