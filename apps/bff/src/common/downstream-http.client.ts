import { Injectable, Logger } from '@nestjs/common';
import { setTimeout as delay } from 'node:timers/promises';
import { CircuitBreakerService } from './circuit-breaker.service.js';
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
    private readonly circuitBreaker: CircuitBreakerService,
  ) {}

  async request(
    service: DownstreamServiceName,
    url: string,
    options?: RequestInit,
    policy: { retryable: boolean } = { retryable: false },
  ): Promise<Response> {
    return this.circuitBreaker.execute(service, () =>
      this.requestWithRetry(service, url, options, policy),
    );
  }

  private async requestWithRetry(
    service: DownstreamServiceName,
    url: string,
    options: RequestInit | undefined,
    policy: { retryable: boolean },
  ): Promise<Response> {
    const maxAttempts = policy.retryable ? this.config.retryCount + 1 : 1;

    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      let response: Response;

      try {
        response = await fetch(url, {
          ...options,
          signal: AbortSignal.timeout(this.config.timeoutMs),
        });
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

      if (isTransientStatus(response.status)) {
        if (attempt < maxAttempts) {
          await this.retryAfterFailure(
            service,
            attempt + 1,
            `http_${response.status}`,
          );
          continue;
        }

        this.logger.warn({
          service,
          attempt,
          correlationId: this.correlationIds.get() ?? 'unknown',
          reason: `http_${response.status}`,
          message: 'Downstream request failed',
        });
        throw new DownstreamServiceUnavailableException(service);
      }

      if (response.status >= 500) {
        throw new DownstreamServiceUnavailableException(service);
      }

      return response;
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
