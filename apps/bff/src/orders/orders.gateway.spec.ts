import { BadGatewayException } from '@nestjs/common';
import { OrdersGateway } from './orders.gateway.js';

describe('OrdersGateway', () => {
  beforeEach(() => {
    process.env.ORDER_SERVICE_URL = 'http://order-service:3001/';
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete process.env.ORDER_SERVICE_URL;
  });

  it('lists orders from the Order Service', async () => {
    const orders = [
      {
        id: 'order-123',
        customerId: 'customer-123',
        items: [{ productId: 'product-001', quantity: 1 }],
        status: 'CREATED',
        createdAt: '2026-10-02T12:00:00.000Z',
      },
    ];
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify(orders), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    const gateway = new OrdersGateway();

    await expect(gateway.findAll()).resolves.toEqual(orders);
    expect(fetchMock).toHaveBeenCalledWith('http://order-service:3001/orders');
  });

  it('creates an order and propagates the correlation ID', async () => {
    const input = {
      customerId: 'customer-123',
      items: [{ productId: 'product-001', quantity: 1 }],
    };
    const order = {
      id: 'order-123',
      ...input,
      status: 'CREATED',
      createdAt: '2026-10-02T12:00:00.000Z',
    };
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify(order), { status: 201 }));
    vi.stubGlobal('fetch', fetchMock);

    const gateway = new OrdersGateway();

    await expect(gateway.create(input, 'front-test-001')).resolves.toEqual(
      order,
    );
    expect(fetchMock).toHaveBeenCalledWith('http://order-service:3001/orders', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-correlation-id': 'front-test-001',
      },
      body: JSON.stringify(input),
    });
  });

  it('maps a connection failure to BadGatewayException', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    const gateway = new OrdersGateway();

    await expect(
      gateway.create(
        {
          customerId: 'customer-123',
          items: [{ productId: 'product-001', quantity: 1 }],
        },
        'front-test-001',
      ),
    ).rejects.toBeInstanceOf(BadGatewayException);
  });
});
