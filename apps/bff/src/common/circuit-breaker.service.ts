import { Injectable, Logger } from '@nestjs/common';
import { CorrelationIdService } from './correlation-id.service.js';
import { DownstreamConfigService } from './downstream-config.service.js';
import {
  DownstreamServiceUnavailableException,
  type DownstreamServiceName,
} from './downstream-service.exception.js';

type CircuitState = 'CLOSED' | 'OPEN' | 'HALF_OPEN';

interface Circuit {
  state: CircuitState;
  failures: number;
  openedAt?: number;
  halfOpenInFlight: boolean;
}

@Injectable()
export class CircuitBreakerService {
  private readonly logger = new Logger(CircuitBreakerService.name);
  private readonly circuits = new Map<DownstreamServiceName, Circuit>();

  constructor(
    private readonly config: DownstreamConfigService,
    private readonly correlationIds: CorrelationIdService,
  ) {}

  async execute<T>(
    service: DownstreamServiceName,
    operation: () => Promise<T>,
  ): Promise<T> {
    const circuit = this.getCircuit(service);

    if (circuit.state === 'OPEN') {
      const elapsed = Date.now() - (circuit.openedAt ?? 0);
      if (elapsed < this.config.circuitResetTimeoutMs) {
        throw new DownstreamServiceUnavailableException(service);
      }

      circuit.state = 'HALF_OPEN';
      circuit.halfOpenInFlight = true;
      this.logTransition(service, 'circuit half-open');
    } else if (circuit.state === 'HALF_OPEN' && circuit.halfOpenInFlight) {
      throw new DownstreamServiceUnavailableException(service);
    }

    try {
      const result = await operation();
      if (circuit.state === 'HALF_OPEN') {
        this.logTransition(service, 'circuit closed');
      }
      circuit.state = 'CLOSED';
      circuit.failures = 0;
      circuit.openedAt = undefined;
      circuit.halfOpenInFlight = false;
      return result;
    } catch (error) {
      circuit.halfOpenInFlight = false;
      circuit.failures += 1;

      if (
        circuit.state === 'HALF_OPEN' ||
        circuit.failures >= this.config.circuitFailureThreshold
      ) {
        circuit.state = 'OPEN';
        circuit.openedAt = Date.now();
        this.logTransition(service, 'circuit opened');
      }

      throw error;
    }
  }

  private getCircuit(service: DownstreamServiceName): Circuit {
    const current = this.circuits.get(service);
    if (current) return current;

    const circuit: Circuit = {
      state: 'CLOSED',
      failures: 0,
      halfOpenInFlight: false,
    };
    this.circuits.set(service, circuit);
    return circuit;
  }

  private logTransition(service: DownstreamServiceName, message: string): void {
    this.logger.warn({
      service,
      correlationId: this.correlationIds.get() ?? 'unknown',
      message,
    });
  }
}
