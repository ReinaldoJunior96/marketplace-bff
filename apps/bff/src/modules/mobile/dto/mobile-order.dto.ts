import type { Order } from '../../../orders/order.js';

export class MobileOrderDto {
  id: string;
  status: Order['status'];
  itemsCount: number;
  createdAt: string;

  constructor(order: Order) {
    this.id = order.id;
    this.status = order.status;
    this.itemsCount = order.items.length;
    this.createdAt = order.createdAt;
  }
}
