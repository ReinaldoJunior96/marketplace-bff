import { Global, Module } from '@nestjs/common';
import { CircuitBreakerService } from './circuit-breaker.service.js';
import { CorrelationIdService } from './correlation-id.service.js';
import { DownstreamConfigService } from './downstream-config.service.js';
import { DownstreamFallbackService } from './downstream-fallback.service.js';
import { DownstreamHttpClient } from './downstream-http.client.js';

@Global()
@Module({
  providers: [
    CircuitBreakerService,
    CorrelationIdService,
    DownstreamConfigService,
    DownstreamFallbackService,
    DownstreamHttpClient,
  ],
  exports: [
    CircuitBreakerService,
    CorrelationIdService,
    DownstreamConfigService,
    DownstreamFallbackService,
    DownstreamHttpClient,
  ],
})
export class CommonModule {}
