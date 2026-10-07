import { fuzzLatLon } from './grid';

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/**
 * Stored cells are precision 7 (~150 m), aligned with the fuzz grid.
 * Nearby queries use precision 5 (~4.9 km): the cell plus its 8 neighbors
 * cover the 10 km Plus radius without returning raw coordinates.
 */
export const STORE_PRECISION = 7;
export const QUERY_PRECISION = 5;

type Direction = 'n' | 's' | 'e' | 'w';

const NEIGHBORS: Record<Direction, [string, string]> = {
  n: ['p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'bc01fg45238967deuvhjyznpkmstqrwx'],
  s: ['14365h7k9dcfesgujnmqp0r2twvyx8zb', '238967debc01fg45kmstqrwxuvhjyznp'],
  e: ['bc01fg45238967deuvhjyznpkmstqrwx', 'p0r21436x8zb9dcf5h7kjnmqesgutwvy'],
  w: ['238967debc01fg45kmstqrwxuvhjyznp', '14365h7k9dcfesgujnmqp0r2twvyx8zb'],
};

const BORDERS: Record<Direction, [string, string]> = {
  n: ['prxz', 'bcfguvyz'],
  s: ['028b', '0145hjnp'],
  e: ['bcfguvyz', 'prxz'],
  w: ['0145hjnp', '028b'],
};

export function encodeGeohash(latitude: number, longitude: number, precision: number): string {
  if (!Number.isInteger(precision) || precision < 1 || precision > 12) {
    throw new Error('invalid precision');
  }
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let geohash = '';
  let latMin = -90;
  let latMax = 90;
  let lonMin = -180;
  let lonMax = 180;

  while (geohash.length < precision) {
    if (evenBit) {
      const mid = (lonMin + lonMax) / 2;
      if (longitude >= mid) {
        idx = idx * 2 + 1;
        lonMin = mid;
      } else {
        idx *= 2;
        lonMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        idx = idx * 2 + 1;
        latMin = mid;
      } else {
        idx *= 2;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    bit += 1;
    if (bit === 5) {
      geohash += BASE32.charAt(idx);
      bit = 0;
      idx = 0;
    }
  }
  return geohash;
}

export function decodeGeohash(hash: string): { latitude: number; longitude: number } | null {
  if (!/^[0123456789bcdefghjkmnpqrstuvwxyz]+$/.test(hash)) return null;
  let evenBit = true;
  let latMin = -90;
  let latMax = 90;
  let lonMin = -180;
  let lonMax = 180;
  for (const ch of hash) {
    const idx = BASE32.indexOf(ch);
    for (let n = 4; n >= 0; n -= 1) {
      const bitN = (idx >> n) & 1;
      if (evenBit) {
        const mid = (lonMin + lonMax) / 2;
        if (bitN === 1) lonMin = mid;
        else lonMax = mid;
      } else {
        const mid = (latMin + latMax) / 2;
        if (bitN === 1) latMin = mid;
        else latMax = mid;
      }
      evenBit = !evenBit;
    }
  }
  return {
    latitude: (latMin + latMax) / 2,
    longitude: (lonMin + lonMax) / 2,
  };
}

function adjacent(hash: string, dir: Direction): string {
  const last = hash.slice(-1);
  const type = hash.length % 2;
  let parent = hash.slice(0, -1);
  if (BORDERS[dir][type].includes(last) && parent.length > 0) {
    parent = adjacent(parent, dir);
  }
  const index = NEIGHBORS[dir][type].indexOf(last);
  if (index < 0) throw new Error('bad geohash');
  return parent + BASE32.charAt(index);
}

/** The cell itself plus the 8 adjacent cells. */
export function geohashNeighbors(hash: string): string[] {
  const normalized = hash.toLowerCase();
  const north = adjacent(normalized, 'n');
  const south = adjacent(normalized, 's');
  const east = adjacent(normalized, 'e');
  const west = adjacent(normalized, 'w');
  return Array.from(new Set([
    normalized,
    north,
    south,
    east,
    west,
    adjacent(north, 'e'),
    adjacent(north, 'w'),
    adjacent(south, 'e'),
    adjacent(south, 'w'),
  ]));
}

export function storedGeohash(latitude: number, longitude: number): string {
  const fuzzed = fuzzLatLon(latitude, longitude);
  return encodeGeohash(fuzzed.latitude, fuzzed.longitude, STORE_PRECISION);
}

export function queryPrefixesFor(latitude: number, longitude: number): string[] {
  const cell = encodeGeohash(latitude, longitude, QUERY_PRECISION);
  return geohashNeighbors(cell);
}

export function prefixRange(prefix: string): { start: string; end: string } {
  return { start: prefix, end: `${prefix}\uf8ff` };
}
