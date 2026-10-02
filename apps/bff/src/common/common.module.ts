import { Global, Module } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';
import { DownstreamConfigService } from './downstream-config.service.js';
import { DownstreamHttpClient } from './downstream-http.client.js';

@Global()
@Module({
  providers: [
    CorrelationIdService,
    DownstreamConfigService,
    DownstreamHttpClient,
  ],
  exports: [
    CorrelationIdService,
    DownstreamConfigService,
    DownstreamHttpClient,
  ],
})
export class CommonModule {}
