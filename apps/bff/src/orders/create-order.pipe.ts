import {
  BadRequestException,
  Injectable,
  type PipeTransform,
} from '@nestjs/common';
import {
  CreateOrderDto,
  type CreateOrderItemDto,
} from './dto/create-order.dto.js';

@Injectable()
export class CreateOrderPipe implements PipeTransform<unknown, CreateOrderDto> {
  transform(value: unknown): CreateOrderDto {
    if (!isRecord(value) || !isNonEmptyString(value.customerId)) {
      throw new BadRequestException('customerId must be a non-empty string');
    }

    if (!Array.isArray(value.items) || value.items.length === 0) {
      throw new BadRequestException('items must be a non-empty array');
    }

    const items = value.items.map((item, index) =>
      this.validateItem(item, index),
    );

    return {
      customerId: value.customerId.trim(),
      items,
    };
  }

  private validateItem(value: unknown, index: number): CreateOrderItemDto {
    if (!isRecord(value) || !isNonEmptyString(value.productId)) {
      throw new BadRequestException(
        `items[${index}].productId must be a non-empty string`,
      );
    }

    if (!Number.isInteger(value.quantity) || (value.quantity as number) <= 0) {
      throw new BadRequestException(
        `items[${index}].quantity must be a positive integer`,
      );
    }

    return {
      productId: value.productId.trim(),
      quantity: value.quantity as number,
    };
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}
