import { BadRequestException } from '@nestjs/common';
import { CreateOrderPipe } from './create-order.pipe.js';

describe('CreateOrderPipe', () => {
  const pipe = new CreateOrderPipe();

  it('validates and adapts the client payload', () => {
    expect(
      pipe.transform({
        customerId: ' customer-123 ',
        ignored: 'client-only-field',
        items: [
          {
            productId: ' product-001 ',
            quantity: 2,
            ignored: true,
          },
        ],
      }),
    ).toEqual({
      customerId: 'customer-123',
      items: [{ productId: 'product-001', quantity: 2 }],
    });
  });

  it.each([
    {},
    { customerId: '', items: [] },
    { customerId: 'customer-123', items: [] },
    {
      customerId: 'customer-123',
      items: [{ productId: '', quantity: 1 }],
    },
    {
      customerId: 'customer-123',
      items: [{ productId: 'product-001', quantity: 0 }],
    },
    {
      customerId: 'customer-123',
      items: [{ productId: 'product-001', quantity: 1.5 }],
    },
  ])('rejects an invalid client payload', (payload) => {
    expect(() => pipe.transform(payload)).toThrow(BadRequestException);
  });
});
