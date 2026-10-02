import { BadGatewayException, NotFoundException } from '@nestjs/common';
import { CatalogGateway } from './catalog.gateway.js';

describe('CatalogGateway', () => {
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

    const gateway = new CatalogGateway();

    await expect(gateway.findAll()).resolves.toEqual(products);
    expect(fetchMock).toHaveBeenCalledWith(
      'http://catalog-service:3003/products',
    );
  });

  it('maps a downstream 404 to NotFoundException', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(null, { status: 404 })),
    );

    const gateway = new CatalogGateway();

    await expect(gateway.findById('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('maps a connection failure to BadGatewayException', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    const gateway = new CatalogGateway();

    await expect(gateway.findAll()).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });
});
