export class CreateOrderItemDto {
  productId: string;
  quantity: number;
}

export class CreateOrderDto {
  customerId: string;
  items: CreateOrderItemDto[];
}
