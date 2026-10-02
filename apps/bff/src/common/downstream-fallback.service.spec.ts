import { Logger } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';
import { DownstreamFallbackService } from './downstream-fallback.service.js';

describe('DownstreamFallbackService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('does not mask a critical dependency failure', async () => {
    const service = new DownstreamFallbackService(new CorrelationIdService());
    const failure = new Error('critical dependency failed');

    await expect(
      service.execute({
        service: 'catalog-service',
        operation: () => Promise.reject(failure),
      }),
    ).rejects.toBe(failure);
  });

  it('allows an explicit fallback for an optional dependency', async () => {
    const warn = vi
      .spyOn(Logger.prototype, 'warn')
      .mockImplementation(() => {});
    const correlationIds = new CorrelationIdService();
    const service = new DownstreamFallbackService(correlationIds);

    await correlationIds.run('fallback-test-001', async () => {
      await expect(
        service.execute<string[]>({
          service: 'optional-recommendations',
          operation: () => Promise.reject(new Error('offline')),
          fallback: () => [],
        }),
      ).resolves.toEqual([]);
    });

    expect(warn).toHaveBeenCalledWith({
      service: 'optional-recommendations',
      correlationId: 'fallback-test-001',
      message: 'Optional dependency fallback applied',
    });
  });
});
