import { Controller, Get, Res } from '@nestjs/common';
import { DownstreamConfigService } from './common/downstream-config.service.js';

interface StatusResponse {
  status(statusCode: number): unknown;
}

interface ReadinessResponse {
  status: 'ready' | 'not_ready';
  dependencies: Record<string, 'up' | 'down'>;
}

@Controller('health')
export class HealthController {
  constructor(private readonly config: DownstreamConfigService) {}

  @Get()
  getHealth(): { status: string } {
    return { status: 'ok' };
  }

  @Get('live')
  getLiveness(): { status: 'live' } {
    return { status: 'live' };
  }

  @Get('ready')
  async getReadiness(
    @Res({ passthrough: true }) response: StatusResponse,
  ): Promise<ReadinessResponse> {
    const [catalog, order] = await Promise.all([
      this.probe(process.env.CATALOG_SERVICE_URL),
      this.probe(process.env.ORDER_SERVICE_URL),
    ]);
    const ready = catalog === 'up' && order === 'up';

    if (!ready) response.status(503);
    return {
      status: ready ? 'ready' : 'not_ready',
      dependencies: { catalog, order },
    };
  }

  private async probe(baseUrl: string | undefined): Promise<'up' | 'down'> {
    if (!baseUrl) return 'down';

    try {
      const response = await fetch(
        `${baseUrl.replace(/\/$/, '')}/health/ready`,
        { signal: AbortSignal.timeout(this.config.timeoutMs) },
      );
      return response.ok ? 'up' : 'down';
    } catch {
      return 'down';
    }
  }
}
