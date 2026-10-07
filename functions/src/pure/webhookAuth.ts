import { timingSafeEqual } from 'node:crypto';

export type WebhookAuthError = 'missing_secret' | 'unauthorized';

/**
 * Pure auth check. Callers must return 401 before touching Firebase
 * when this returns an error, including when the secret is unset.
 */
export function webhookAuthError(
  authorizationHeader: string | undefined | null,
  secret: string | undefined | null,
): WebhookAuthError | null {
  if (typeof secret !== 'string' || secret.length === 0) return 'missing_secret';
  if (typeof authorizationHeader !== 'string') return 'unauthorized';
  const match = /^Bearer\s+(\S+)\s*$/i.exec(authorizationHeader);
  if (!match) return 'unauthorized';
  const provided = Buffer.from(match[1]);
  const expected = Buffer.from(secret);
  if (provided.length !== expected.length) return 'unauthorized';
  if (!timingSafeEqual(provided, expected)) return 'unauthorized';
  return null;
}
