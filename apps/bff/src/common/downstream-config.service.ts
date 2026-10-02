import { Injectable } from '@nestjs/common';

const DEFAULT_DOWNSTREAM_TIMEOUT_MS = 2_000;
const DEFAULT_DOWNSTREAM_RETRY_COUNT = 2;
const DEFAULT_DOWNSTREAM_RETRY_BACKOFF_MS = 100;
const DEFAULT_CIRCUIT_FAILURE_THRESHOLD = 3;
const DEFAULT_CIRCUIT_RESET_TIMEOUT_MS = 5_000;

@Injectable()
export class DownstreamConfigService {
  readonly timeoutMs = parsePositiveInteger(
    process.env.DOWNSTREAM_TIMEOUT_MS,
    DEFAULT_DOWNSTREAM_TIMEOUT_MS,
    'DOWNSTREAM_TIMEOUT_MS',
  );
  readonly retryCount = parseNonNegativeInteger(
    process.env.DOWNSTREAM_RETRY_COUNT,
    DEFAULT_DOWNSTREAM_RETRY_COUNT,
    'DOWNSTREAM_RETRY_COUNT',
  );
  readonly retryBackoffMs = parseNonNegativeInteger(
    process.env.DOWNSTREAM_RETRY_BACKOFF_MS,
    DEFAULT_DOWNSTREAM_RETRY_BACKOFF_MS,
    'DOWNSTREAM_RETRY_BACKOFF_MS',
  );
  readonly circuitFailureThreshold = parsePositiveInteger(
    process.env.CIRCUIT_FAILURE_THRESHOLD,
    DEFAULT_CIRCUIT_FAILURE_THRESHOLD,
    'CIRCUIT_FAILURE_THRESHOLD',
  );
  readonly circuitResetTimeoutMs = parsePositiveInteger(
    process.env.CIRCUIT_RESET_TIMEOUT_MS,
    DEFAULT_CIRCUIT_RESET_TIMEOUT_MS,
    'CIRCUIT_RESET_TIMEOUT_MS',
  );
}

function parseNonNegativeInteger(
  value: string | undefined,
  fallback: number,
  name: string,
): number {
  if (value === undefined) return fallback;

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${name} must be a non-negative integer`);
  }

  return parsed;
}

function parsePositiveInteger(
  value: string | undefined,
  fallback: number,
  name: string,
): number {
  if (value === undefined) return fallback;

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }

  return parsed;
}
