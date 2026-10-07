const COORDINATE_KEYS = new Set(['latitude', 'longitude']);

export function withoutCoordinates(value: unknown): unknown {
  if (Array.isArray(value)) return value.map((item) => withoutCoordinates(item));
  if (value instanceof Date) return value;
  if (value && typeof value === 'object') {
    if ('toDate' in value && typeof (value as { toDate: unknown }).toDate === 'function') {
      return value;
    }
    const out: Record<string, unknown> = {};
    for (const [key, inner] of Object.entries(value as Record<string, unknown>)) {
      if (COORDINATE_KEYS.has(key)) continue;
      out[key] = withoutCoordinates(inner);
    }
    return out;
  }
  return value;
}

export function locationExport(
  data: Record<string, unknown> | null | undefined,
): { geohash: string; updatedAt: unknown } | null {
  if (!data || typeof data.geohash !== 'string' || data.geohash.length === 0) return null;
  return {
    geohash: data.geohash,
    updatedAt: data.updatedAt ?? null,
  };
}
