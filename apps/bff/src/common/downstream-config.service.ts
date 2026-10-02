import { Injectable } from '@nestjs/common';

const DEFAULT_DOWNSTREAM_TIMEOUT_MS = 2_000;

@Injectable()
export class DownstreamConfigService {
  readonly timeoutMs = parsePositiveInteger(
    process.env.DOWNSTREAM_TIMEOUT_MS,
    DEFAULT_DOWNSTREAM_TIMEOUT_MS,
    'DOWNSTREAM_TIMEOUT_MS',
  );
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
