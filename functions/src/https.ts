import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

export const REGION = 'southamerica-east1';

export const callableOptions = {
  region: REGION,
  enforceAppCheck: true,
} as const;

export function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return uid;
}

export function asRecord(data: unknown): Record<string, unknown> {
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    return data as Record<string, unknown>;
  }
  return {};
}

export function invalid(message: string): HttpsError {
  return new HttpsError('invalid-argument', message);
}
