import { HttpException, HttpStatus } from '@nestjs/common';

export type DownstreamServiceName = 'catalog-service' | 'order-service';

export class DownstreamServiceUnavailableException extends HttpException {
  constructor(service: DownstreamServiceName) {
    const publicName = service === 'catalog-service' ? 'Catalog' : 'Order';
    super(
      `${publicName} service is unavailable`,
      HttpStatus.SERVICE_UNAVAILABLE,
    );
  }
}
