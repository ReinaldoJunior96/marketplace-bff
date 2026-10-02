import { Logger } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';
import type { DownstreamConfigService } from './downstream-config.service.js';
import { DownstreamHttpClient } from './downstream-http.client.js';
import { DownstreamServiceUnavailableException } from './downstream-service.exception.js';

describe('DownstreamHttpClient', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('aborts delayed requests and logs the service and correlation ID', async () => {
    const warn = vi
      .spyOn(Logger.prototype, 'warn')
      .mockImplementation(() => {});
    vi.stubGlobal(
      'fetch',
      vi.fn((_url: string, options: RequestInit) => {
        return new Promise((_resolve, reject) => {
          options.signal?.addEventListener(
            'abort',
            () => reject(options.signal?.reason),
            { once: true },
          );
        });
      }),
    );
    const correlationIds = new CorrelationIdService();
    const client = new DownstreamHttpClient(
      { timeoutMs: 10 } as DownstreamConfigService,
      correlationIds,
    );

    await correlationIds.run('timeout-test-001', async () => {
      await expect(
        client.request(
          'catalog-service',
          'http://catalog-service:3003/products',
        ),
      ).rejects.toBeInstanceOf(DownstreamServiceUnavailableException);
    });

    expect(warn).toHaveBeenCalledWith(
      expect.objectContaining({
        service: 'catalog-service',
        correlationId: 'timeout-test-001',
        reason: 'timeout',
      }),
    );
  });
});
