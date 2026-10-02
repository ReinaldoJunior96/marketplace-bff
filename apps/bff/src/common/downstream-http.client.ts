import { Injectable, Logger } from '@nestjs/common';
import { setTimeout as delay } from 'node:timers/promises';
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
    policy: { retryable: boolean } = { retryable: false },
  ): Promise<Response> {
    const maxAttempts = policy.retryable ? this.config.retryCount + 1 : 1;

    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        const response = await fetch(url, {
          ...options,
          signal: AbortSignal.timeout(this.config.timeoutMs),
        });

        if (isTransientStatus(response.status) && attempt < maxAttempts) {
          await this.retryAfterFailure(
            service,
            attempt + 1,
            `http_${response.status}`,
          );
          continue;
        }

        return response;
      } catch (error) {
        const reason = isTimeout(error) ? 'timeout' : 'connection_error';
        if (attempt < maxAttempts) {
          await this.retryAfterFailure(service, attempt + 1, reason);
          continue;
        }

        this.logger.warn({
          service,
          attempt,
          correlationId: this.correlationIds.get() ?? 'unknown',
          reason,
          message: error instanceof Error ? error.message : String(error),
        });
        throw new DownstreamServiceUnavailableException(service);
      }
    }

    throw new DownstreamServiceUnavailableException(service);
  }

  private async retryAfterFailure(
    service: DownstreamServiceName,
    attempt: number,
    reason: string,
  ): Promise<void> {
    this.logger.warn({
      service,
      attempt,
      correlationId: this.correlationIds.get() ?? 'unknown',
      reason,
      message: 'Retrying downstream request',
    });
    await delay(this.config.retryBackoffMs);
  }
}

function isTimeout(error: unknown): boolean {
  return error instanceof Error && error.name === 'TimeoutError';
}

function isTransientStatus(status: number): boolean {
  return status === 502 || status === 503 || status === 504;
}
