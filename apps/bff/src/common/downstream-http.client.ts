import { Injectable, Logger } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';
import { DownstreamConfigService } from './downstream-config.service.js';
import {
  DownstreamServiceUnavailableException,
  type DownstreamServiceName,
} from './downstream-service.exception.js';

@Injectable()
export class DownstreamHttpClient {
  private readonly logger = new Logger(DownstreamHttpClient.name);

  constructor(
    private readonly config: DownstreamConfigService,
    private readonly correlationIds: CorrelationIdService,
  ) {}

  async request(
    service: DownstreamServiceName,
    url: string,
    options?: RequestInit,
  ): Promise<Response> {
    try {
      return await fetch(url, {
        ...options,
        signal: AbortSignal.timeout(this.config.timeoutMs),
      });
    } catch (error) {
      this.logger.warn({
        service,
        correlationId: this.correlationIds.get() ?? 'unknown',
        reason: isTimeout(error) ? 'timeout' : 'connection_error',
        message: error instanceof Error ? error.message : String(error),
      });
      throw new DownstreamServiceUnavailableException(service);
    }
  }
}

function isTimeout(error: unknown): boolean {
  return error instanceof Error && error.name === 'TimeoutError';
}
