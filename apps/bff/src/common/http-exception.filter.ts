import { STATUS_CODES } from 'node:http';
import {
  Catch,
  HttpException,
  HttpStatus,
  Logger,
  type ArgumentsHost,
  type ExceptionFilter,
} from '@nestjs/common';
import type { CorrelatedRequest } from './correlation-id.middleware.js';
import { CorrelationIdService } from './correlation-id.service.js';

interface ErrorResponse {
  status(statusCode: number): ErrorResponse;
  send(body: StandardErrorBody): unknown;
}

interface StandardErrorBody {
  statusCode: number;
  error: string;
  message: string | string[];
  correlationId: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  constructor(private readonly correlationIds: CorrelationIdService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<CorrelatedRequest>();
    const response = context.getResponse<ErrorResponse>();
    const statusCode =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const correlationId =
      request.correlationId ?? this.correlationIds.get() ?? 'unknown';

    if (statusCode >= 500) {
      this.logger.error({
        correlationId,
        statusCode,
        error:
          exception instanceof Error ? exception.message : String(exception),
        stack: exception instanceof Error ? exception.stack : undefined,
      });
    }

    response.status(statusCode).send({
      statusCode,
      error: this.getErrorName(exception, statusCode),
      message: this.getPublicMessage(exception),
      correlationId,
    });
  }

  private getErrorName(exception: unknown, statusCode: number): string {
    if (exception instanceof HttpException) {
      const body = exception.getResponse();
      if (typeof body === 'object' && body !== null && 'error' in body) {
        const error = body.error;
        if (typeof error === 'string') return error;
      }
    }

    return STATUS_CODES[statusCode] ?? 'Error';
  }

  private getPublicMessage(exception: unknown): string | string[] {
    if (!(exception instanceof HttpException)) {
      return 'Internal server error';
    }

    const body = exception.getResponse();
    if (typeof body === 'string') return body;
    if (typeof body === 'object' && body !== null && 'message' in body) {
      const message = body.message;
      if (typeof message === 'string' || Array.isArray(message)) return message;
    }

    return exception.message;
  }
}
