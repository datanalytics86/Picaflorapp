export const LOCATION_MIN_INTERVAL_MS = 20_000;

export function locationUpdateAllowed(previous: Date | null, now: Date): boolean {
  if (!previous) return true;
  return now.getTime() - previous.getTime() >= LOCATION_MIN_INTERVAL_MS;
}
