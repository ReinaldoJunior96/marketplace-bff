import type { Order, OrderItem } from '../../../orders/order.js';

export class WebOrderDto {
  id: string;
  customerId: string;
  items: OrderItem[];
  status: Order['status'];
  createdAt: string;

  constructor(order: Order) {
    this.id = order.id;
    this.customerId = order.customerId;
    this.items = order.items.map((item) => ({ ...item }));
    this.status = order.status;
    this.createdAt = order.createdAt;
  }
}
