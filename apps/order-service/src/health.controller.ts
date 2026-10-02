import { Controller, Get, Res } from '@nestjs/common';
import { RabbitMqPublisher } from './messaging/rabbitmq.publisher.js';

interface StatusResponse {
  status(statusCode: number): unknown;
}

@Controller('health')
export class HealthController {
  constructor(private readonly publisher: RabbitMqPublisher) {}

  @Get()
  getHealth(): { status: string } {
    return { status: 'ok' };
  }

  @Get('live')
  getLiveness(): { status: 'live' } {
    return { status: 'live' };
  }

  @Get('ready')
  getReadiness(@Res({ passthrough: true }) response: StatusResponse) {
    const rabbitmq = this.publisher.isReady() ? 'up' : 'down';
    if (rabbitmq === 'down') response.status(503);
    return {
      status: rabbitmq === 'up' ? 'ready' : 'not_ready',
      dependencies: { rabbitmq },
    };
  }
}
