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
      {
        timeoutMs: 10,
        retryCount: 0,
        retryBackoffMs: 0,
      } as DownstreamConfigService,
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

  it('retries transient responses with a bounded backoff', async () => {
    const warn = vi
      .spyOn(Logger.prototype, 'warn')
      .mockImplementation(() => {});
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response(null, { status: 503 }))
      .mockResolvedValueOnce(new Response('{}', { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);
    const correlationIds = new CorrelationIdService();
    const client = new DownstreamHttpClient(
      {
        timeoutMs: 2_000,
        retryCount: 2,
        retryBackoffMs: 0,
      } as DownstreamConfigService,
      correlationIds,
    );

    const response = await correlationIds.run('retry-test-001', () =>
      client.request(
        'catalog-service',
        'http://catalog-service:3003/products',
        undefined,
        {
          retryable: true,
        },
      ),
    );

    expect(response.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(warn).toHaveBeenCalledWith({
      service: 'catalog-service',
      attempt: 2,
      correlationId: 'retry-test-001',
      reason: 'http_503',
      message: 'Retrying downstream request',
    });
  });

  it('does not retry non-transient responses', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(null, { status: 404 }));
    vi.stubGlobal('fetch', fetchMock);
    const client = new DownstreamHttpClient(
      {
        timeoutMs: 2_000,
        retryCount: 2,
        retryBackoffMs: 0,
      } as DownstreamConfigService,
      new CorrelationIdService(),
    );

    const response = await client.request(
      'catalog-service',
      'http://catalog-service:3003/products/missing',
      undefined,
      { retryable: true },
    );

    expect(response.status).toBe(404);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
