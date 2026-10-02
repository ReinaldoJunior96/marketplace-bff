import { Module } from '@nestjs/common';
import { RabbitMqPublisher } from './rabbitmq.publisher.js';

@Module({
  providers: [RabbitMqPublisher],
  exports: [RabbitMqPublisher],
})
export class MessagingModule {}
