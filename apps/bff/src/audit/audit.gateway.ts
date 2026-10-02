import { Injectable } from '@nestjs/common';
import { DownstreamHttpClient } from '../common/downstream-http.client.js';
import { DownstreamServiceUnavailableException } from '../common/downstream-service.exception.js';
import type { AuditEvent } from './audit-event.js';

@Injectable()
export class AuditGateway {
  private readonly baseUrl: string;

  constructor(private readonly http: DownstreamHttpClient) {
    const url = process.env.AUDIT_SERVICE_URL;

    if (!url) {
      throw new Error('AUDIT_SERVICE_URL is required');
    }

    this.baseUrl = url.replace(/\/$/, '');
  }

  async findAll(): Promise<AuditEvent[]> {
    let response: Response;

    try {
      response = await this.http.request(
        'audit-service',
        `${this.baseUrl}/logs`,
        undefined,
        { retryable: true },
      );
    } catch (error) {
      if (error instanceof DownstreamServiceUnavailableException) throw error;
      throw new DownstreamServiceUnavailableException('audit-service');
    }

    if (!response.ok) {
      throw new DownstreamServiceUnavailableException('audit-service');
    }

    return (await response.json()) as AuditEvent[];
  }
}
