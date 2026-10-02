import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  getHealth(): { status: string } {
    return { status: 'ok' };
  }

  @Get('live')
  getLiveness(): { status: 'live' } {
    return { status: 'live' };
  }

  @Get('ready')
  getReadiness(): { status: 'ready'; dependencies: Record<string, never> } {
    return { status: 'ready', dependencies: {} };
  }
}
