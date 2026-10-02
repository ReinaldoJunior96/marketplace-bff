import { HttpException, HttpStatus } from '@nestjs/common';

export type DownstreamServiceName = 'Catalog' | 'Order';

export class DownstreamServiceUnavailableException extends HttpException {
  constructor(service: DownstreamServiceName) {
    super(`${service} service is unavailable`, HttpStatus.SERVICE_UNAVAILABLE);
  }
}
