/** ~155 m. Matches the client grid (0.0014°). Half-steps use Math.round (half toward +∞). */
export const GRID_DEGREES = 0.0014;

export function fuzzCoordinate(value: number): number {
  if (!Number.isFinite(value)) {
    throw new Error('invalid coordinate');
  }
  const steps = Math.round(value / GRID_DEGREES);
  const snapped = steps * GRID_DEGREES;
  return Math.round(snapped * 1e6) / 1e6;
}

export function assertLatLon(
  latitude: unknown,
  longitude: unknown,
): { latitude: number; longitude: number } {
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    throw new Error('coordinates must be numbers');
  }
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    throw new Error('invalid latitude');
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    throw new Error('invalid longitude');
  }
  return { latitude, longitude };
}

export function fuzzLatLon(
  latitude: number,
  longitude: number,
): { latitude: number; longitude: number } {
  return {
    latitude: fuzzCoordinate(latitude),
    longitude: fuzzCoordinate(longitude),
  };
}
