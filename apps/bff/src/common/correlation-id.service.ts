import { AsyncLocalStorage } from 'node:async_hooks';
import { Injectable } from '@nestjs/common';

@Injectable()
export class CorrelationIdService {
  private readonly storage = new AsyncLocalStorage<string>();

  run<T>(correlationId: string, callback: () => T): T {
    return this.storage.run(correlationId, callback);
  }

  get(): string | undefined {
    return this.storage.getStore();
  }
}
