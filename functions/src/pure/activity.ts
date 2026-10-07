export type ActivityBucket = 'ahora' | 'hoy' | 'esta_semana';

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/**
 * ahora: <= 15 min, hoy: < 24 h, esta_semana: <= 7 d.
 * Older than 7 days returns null and must be omitted from nearby.
 */
export function activityBucket(lastActiveAt: Date, now: Date): ActivityBucket | null {
  const elapsed = now.getTime() - lastActiveAt.getTime();
  if (elapsed <= 15 * MINUTE) return 'ahora';
  if (elapsed < DAY) return 'hoy';
  if (elapsed <= 7 * DAY) return 'esta_semana';
  return null;
}

export const LOCATION_MAX_AGE_MS = 7 * DAY;
