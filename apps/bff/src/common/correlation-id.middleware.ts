import { randomUUID } from 'node:crypto';
import { Injectable, type NestMiddleware } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';

export interface CorrelatedRequest {
  headers: Record<string, string | string[] | undefined>;
  correlationId?: string;
}

interface HeaderResponse {
  setHeader(name: string, value: string): unknown;
}

@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  constructor(private readonly correlationIds: CorrelationIdService) {}

  use(
    request: CorrelatedRequest,
    response: HeaderResponse,
    next: () => void,
  ): void {
    const header = request.headers['x-correlation-id'];
    const requestedId = Array.isArray(header) ? header[0] : header;
    const correlationId = requestedId?.trim() || randomUUID();

    request.correlationId = correlationId;
    request.headers['x-correlation-id'] = correlationId;
    response.setHeader('x-correlation-id', correlationId);
    this.correlationIds.run(correlationId, next);
  }
}
