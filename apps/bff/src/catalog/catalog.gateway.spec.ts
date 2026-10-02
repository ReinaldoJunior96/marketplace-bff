import { NotFoundException } from '@nestjs/common';
import { CorrelationIdService } from '../common/correlation-id.service.js';
import type { DownstreamConfigService } from '../common/downstream-config.service.js';
import { DownstreamHttpClient } from '../common/downstream-http.client.js';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import { CatalogGateway } from './catalog.gateway.js';

describe('CatalogGateway', () => {
  const createGateway = () =>
    new CatalogGateway(
      new DownstreamHttpClient(
        {
          timeoutMs: 2_000,
          retryCount: 2,
          retryBackoffMs: 0,
        } as DownstreamConfigService,
        new CorrelationIdService(),
      ),
    );

  beforeEach(() => {
    process.env.CATALOG_SERVICE_URL = 'http://catalog-service:3003';
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.CATALOG_SERVICE_URL;
  });

  it('lists products from the Catalog Service', async () => {
    const products = [{ id: 'product-001', name: 'Teclado Mecânico' }];
    const fetchMock = vi
      .fn()
      .mockResolvedValue(
        new Response(JSON.stringify(products), { status: 200 }),
      );
    vi.stubGlobal('fetch', fetchMock);

    const gateway = createGateway();

    await expect(gateway.findAll()).resolves.toEqual(products);
    expect(fetchMock).toHaveBeenCalledWith(
      'http://catalog-service:3003/products',
      expect.objectContaining({ signal: expect.any(Object) }),
    );
  });

  it('maps a downstream 404 to NotFoundException', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(null, { status: 404 })),
    );

    const gateway = createGateway();

    await expect(gateway.findById('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('maps a connection failure to a controlled service error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    const gateway = createGateway();

    await expect(gateway.findAll()).rejects.toBeInstanceOf(
      DownstreamServiceUnavailableException,
    );
  });
});
