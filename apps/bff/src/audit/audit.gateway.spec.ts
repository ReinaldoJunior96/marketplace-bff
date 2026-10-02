import { CircuitBreakerService } from '../common/circuit-breaker.service.js';
import { CorrelationIdService } from '../common/correlation-id.service.js';
import type { DownstreamConfigService } from '../common/downstream-config.service.js';
import { DownstreamHttpClient } from '../common/downstream-http.client.js';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import { AuditGateway } from './audit.gateway.js';

describe('AuditGateway', () => {
  const createGateway = () => {
    const config = {
      timeoutMs: 2_000,
      retryCount: 0,
      retryBackoffMs: 0,
      circuitFailureThreshold: 3,
      circuitResetTimeoutMs: 5_000,
    } as DownstreamConfigService;
    const correlationIds = new CorrelationIdService();
    return new AuditGateway(
      new DownstreamHttpClient(
        config,
        correlationIds,
        new CircuitBreakerService(config, correlationIds),
      ),
    );
  };

  beforeEach(() => {
    process.env.AUDIT_SERVICE_URL = 'http://audit-service:3002/';
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.AUDIT_SERVICE_URL;
  });

  it('requires AUDIT_SERVICE_URL', () => {
    delete process.env.AUDIT_SERVICE_URL;

    expect(createGateway).toThrow('AUDIT_SERVICE_URL is required');
  });

  it('lists audit events from the Audit Service', async () => {
    const events = [{ eventId: 'event-1', eventType: 'order.created' }];
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify(events), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    await expect(createGateway().findAll()).resolves.toEqual(events);
    expect(fetchMock).toHaveBeenCalledWith(
      'http://audit-service:3002/logs',
      expect.objectContaining({ signal: expect.any(Object) }),
    );
  });

  it('maps downstream failures to a public Audit unavailability error', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(null, { status: 500 })),
    );

    await expect(createGateway().findAll()).rejects.toThrow(
      new DownstreamServiceUnavailableException('audit-service'),
    );
  });
});
