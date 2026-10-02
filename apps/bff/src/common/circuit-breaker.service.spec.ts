import { Logger } from '@nestjs/common';
import { CircuitBreakerService } from './circuit-breaker.service.js';
import { CorrelationIdService } from './correlation-id.service.js';
import type { DownstreamConfigService } from './downstream-config.service.js';
import { DownstreamServiceUnavailableException } from './downstream-service.exception.js';

describe('CircuitBreakerService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('opens, probes in half-open and closes after recovery', async () => {
    const warn = vi
      .spyOn(Logger.prototype, 'warn')
      .mockImplementation(() => {});
    const now = vi.spyOn(Date, 'now').mockReturnValue(0);
    const config = {
      circuitFailureThreshold: 2,
      circuitResetTimeoutMs: 100,
    } as DownstreamConfigService;
    const correlationIds = new CorrelationIdService();
    const breaker = new CircuitBreakerService(config, correlationIds);
    const operation = vi
      .fn<() => Promise<string>>()
      .mockRejectedValueOnce(new Error('offline'))
      .mockRejectedValueOnce(new Error('offline'))
      .mockResolvedValue('recovered');

    await correlationIds.run('circuit-test-001', async () => {
      await expect(
        breaker.execute('catalog-service', operation),
      ).rejects.toThrow('offline');
      await expect(
        breaker.execute('catalog-service', operation),
      ).rejects.toThrow('offline');
      await expect(
        breaker.execute('catalog-service', operation),
      ).rejects.toBeInstanceOf(DownstreamServiceUnavailableException);

      expect(operation).toHaveBeenCalledTimes(2);

      now.mockReturnValue(101);
      await expect(breaker.execute('catalog-service', operation)).resolves.toBe(
        'recovered',
      );
    });

    expect(operation).toHaveBeenCalledTimes(3);
    expect(warn).toHaveBeenCalledWith({
      service: 'catalog-service',
      correlationId: 'circuit-test-001',
      message: 'circuit opened',
    });
    expect(warn).toHaveBeenCalledWith({
      service: 'catalog-service',
      correlationId: 'circuit-test-001',
      message: 'circuit half-open',
    });
    expect(warn).toHaveBeenCalledWith({
      service: 'catalog-service',
      correlationId: 'circuit-test-001',
      message: 'circuit closed',
    });
  });
});
