const EARTH_RADIUS_METERS = 6_371_000;

export type DistanceBucket = 'very_close' | 'm300' | 'm800' | 'km2' | 'km5' | 'km10';

export function haversineMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
    + Math.cos((lat1 * Math.PI) / 180)
      * Math.cos((lat2 * Math.PI) / 180)
      * Math.sin(dLon / 2)
      * Math.sin(dLon / 2);
  return EARTH_RADIUS_METERS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Boundaries are exclusive on the lower bucket: 150 m is m300, not very_close. */
export function distanceBucket(meters: number): DistanceBucket {
  if (meters < 150) return 'very_close';
  if (meters < 450) return 'm300';
  if (meters < 1200) return 'm800';
  if (meters < 2500) return 'km2';
  if (meters < 6000) return 'km5';
  return 'km10';
}

export const FREE_RADIUS_METERS = 5_000;
export const PLUS_RADIUS_METERS = 10_000;

export function capRadiusMeters(requested: number, isPlus: boolean): number {
  const max = isPlus ? PLUS_RADIUS_METERS : FREE_RADIUS_METERS;
  if (!Number.isFinite(requested) || requested <= 0) return max;
  return Math.min(requested, max);
}
