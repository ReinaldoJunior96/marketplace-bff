import { HttpException, HttpStatus } from '@nestjs/common';

export type DownstreamServiceName =
  'catalog-service' | 'order-service' | 'audit-service';

const PUBLIC_NAMES: Record<DownstreamServiceName, string> = {
  'catalog-service': 'Catalog',
  'order-service': 'Order',
  'audit-service': 'Audit',
};

export class DownstreamServiceUnavailableException extends HttpException {
  constructor(service: DownstreamServiceName) {
    super(
      `${PUBLIC_NAMES[service]} service is unavailable`,
      HttpStatus.SERVICE_UNAVAILABLE,
    );
  }
}
