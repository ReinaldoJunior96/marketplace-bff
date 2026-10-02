import { Injectable, Logger } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';

export interface FallbackPolicy<T> {
  service: string;
  operation: () => Promise<T>;
  fallback?: (error: unknown) => Promise<T> | T;
}

@Injectable()
export class DownstreamFallbackService {
  private readonly logger = new Logger(DownstreamFallbackService.name);

  constructor(private readonly correlationIds: CorrelationIdService) {}

  async execute<T>(policy: FallbackPolicy<T>): Promise<T> {
    try {
      return await policy.operation();
    } catch (error) {
      if (!policy.fallback) throw error;

      this.logger.warn({
        service: policy.service,
        correlationId: this.correlationIds.get() ?? 'unknown',
        message: 'Optional dependency fallback applied',
      });
      return policy.fallback(error);
    }
  }
}
