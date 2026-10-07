import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import test from 'node:test';
import { activityBucket } from './pure/activity';
import { ageYears, isAdult } from './pure/age';
import { capRadiusMeters, distanceBucket } from './pure/distance';
import { locationExport, withoutCoordinates } from './pure/exportShape';
import { decodeGeohash, encodeGeohash, geohashNeighbors, queryPrefixesFor, storedGeohash } from './pure/geohash';
import { fuzzCoordinate, fuzzLatLon, GRID_DEGREES } from './pure/grid';
import { moderateText } from './pure/moderate';
import { filterNearbyPeople, type NearbyCandidate } from './pure/nearbyFilter';
import { messagePush } from './pure/push';
import { planFromRevenueCat } from './pure/revenuecat';
import {
  countWavesOnSantiagoDay,
  isPlusActive,
  santiagoDateKey,
  startOfSantiagoDay,
  waveQuotaDecision,
} from './pure/waveQuota';
import { webhookAuthError } from './pure/webhookAuth';

const require = createRequire(__filename);

test('fuzz snaps coordinates onto the 0.0014 degree grid', () => {
  assert.equal(fuzzCoordinate(0), 0);
  assert.equal(fuzzCoordinate(GRID_DEGREES), GRID_DEGREES);
  assert.equal(fuzzCoordinate(0.0007), GRID_DEGREES);
  assert.equal(fuzzCoordinate(0.0002), 0);
  assert.equal(fuzzCoordinate(-33.4567), -33.4572);
  assert.equal(fuzzCoordinate(33.4567), 33.4572);
  const fuzzed = fuzzLatLon(-33.44891, -70.66641);
  assert.equal(fuzzed.latitude, fuzzCoordinate(-33.44891));
  assert.equal(fuzzed.longitude, fuzzCoordinate(-70.66641));
  const steps = fuzzed.latitude / GRID_DEGREES;
  assert.ok(Math.abs(steps - Math.round(steps)) < 1e-6);
  assert.equal(fuzzCoordinate(-33.45), fuzzCoordinate(-33.45 + 0.0002));
  assert.throws(() => fuzzCoordinate(Number.NaN));
});

test('geohash is stable and neighbors include the cell itself', () => {
  assert.equal(encodeGeohash(57.64911, 10.40744, 11), 'u4pruydqqvj');
  assert.equal(encodeGeohash(57.64911, 10.40744, 11), encodeGeohash(57.64911, 10.40744, 11));
  const hash = encodeGeohash(-33.45, -70.66, 5);
  const neighbors = geohashNeighbors(hash);
  assert.equal(neighbors.length, 9);
  assert.ok(neighbors.includes(hash));
  assert.ok(neighbors.every((cell) => cell.length === hash.length));
  const center = decodeGeohash(encodeGeohash(-33.45, -70.66, 7));
  assert.ok(center);
  assert.ok(Math.abs(center.latitude - (-33.45)) < 0.01);
  assert.ok(Math.abs(center.longitude - (-70.66)) < 0.01);
  const prefixes = queryPrefixesFor(-33.45, -70.66);
  assert.ok(prefixes.includes(encodeGeohash(-33.45, -70.66, 5)));
  const rawA = -33.45;
  const rawB = -33.45 + 0.0002;
  assert.equal(storedGeohash(rawA, -70.66), storedGeohash(rawB, -70.66));
});

test('distance buckets use the documented boundaries', () => {
  assert.equal(distanceBucket(0), 'very_close');
  assert.equal(distanceBucket(149.999), 'very_close');
  assert.equal(distanceBucket(150), 'm300');
  assert.equal(distanceBucket(449.999), 'm300');
  assert.equal(distanceBucket(450), 'm800');
  assert.equal(distanceBucket(1199.999), 'm800');
  assert.equal(distanceBucket(1200), 'km2');
  assert.equal(distanceBucket(2499.999), 'km2');
  assert.equal(distanceBucket(2500), 'km5');
  assert.equal(distanceBucket(5999.999), 'km5');
  assert.equal(distanceBucket(6000), 'km10');
  assert.equal(distanceBucket(20000), 'km10');
  assert.equal(capRadiusMeters(99_999, false), 5000);
  assert.equal(capRadiusMeters(99_999, true), 10000);
  assert.equal(capRadiusMeters(800, false), 800);
});

test('activity buckets', () => {
  const now = new Date('2026-10-06T12:00:00.000Z');
  assert.equal(activityBucket(new Date(now.getTime() - 15 * 60 * 1000), now), 'ahora');
  assert.equal(activityBucket(new Date(now.getTime() - 15 * 60 * 1000 - 1), now), 'hoy');
  assert.equal(activityBucket(new Date(now.getTime() - 24 * 60 * 60 * 1000 + 1), now), 'hoy');
  assert.equal(activityBucket(new Date(now.getTime() - 24 * 60 * 60 * 1000), now), 'esta_semana');
  assert.equal(activityBucket(new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000), now), 'esta_semana');
  assert.equal(activityBucket(new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000 - 1), now), null);
});

test('age is 18 on the birthday, not the day before, including leap day', () => {
  const birth = new Date(Date.UTC(2008, 9, 6));
  assert.equal(isAdult(birth, new Date(Date.UTC(2026, 9, 6))), true);
  assert.equal(ageYears(birth, new Date(Date.UTC(2026, 9, 6))), 18);
  assert.equal(isAdult(birth, new Date(Date.UTC(2026, 9, 5))), false);
  assert.equal(ageYears(birth, new Date(Date.UTC(2026, 9, 5))), 17);

  const leap = new Date(Date.UTC(2008, 1, 29));
  assert.equal(isAdult(leap, new Date(Date.UTC(2026, 1, 28))), false);
  assert.equal(isAdult(leap, new Date(Date.UTC(2026, 2, 1))), true);
  assert.equal(ageYears(leap, new Date(Date.UTC(2024, 1, 29))), 16);
});

test('wave quota is 20 per Santiago day for free and unlimited for plus', () => {
  const now = new Date('2026-01-15T15:00:00.000Z');
  assert.equal(santiagoDateKey(new Date('2026-01-15T02:30:00.000Z')), '2026-01-14');
  assert.equal(santiagoDateKey(now), '2026-01-15');
  const start = startOfSantiagoDay(now);
  assert.equal(santiagoDateKey(start), santiagoDateKey(now));
  assert.notEqual(santiagoDateKey(new Date(start.getTime() - 1)), santiagoDateKey(now));
  assert.equal(countWavesOnSantiagoDay([
    new Date('2026-01-15T02:30:00.000Z'),
    new Date('2026-01-15T15:00:00.000Z'),
    new Date('2026-01-14T18:00:00.000Z'),
  ], now), 1);

  assert.equal(isPlusActive('plus', new Date(now.getTime() + 1000), now), true);
  assert.equal(isPlusActive('plus', now, now), false);
  assert.equal(isPlusActive('free', new Date(now.getTime() + 1000), now), false);

  assert.deepEqual(waveQuotaDecision({ isPlus: false, sentToday: 19, note: null }), { ok: true });
  assert.deepEqual(
    waveQuotaDecision({ isPlus: false, sentToday: 20, note: null }),
    { ok: false, reason: 'daily_limit' },
  );
  assert.deepEqual(waveQuotaDecision({ isPlus: true, sentToday: 500, note: 'hola' }), { ok: true });
  assert.deepEqual(
    waveQuotaDecision({ isPlus: false, sentToday: 0, note: 'hola' }),
    { ok: false, reason: 'note_requires_plus' },
  );
  assert.deepEqual(
    waveQuotaDecision({ isPlus: true, sentToday: 0, note: 'x'.repeat(141) }),
    { ok: false, reason: 'note_too_long' },
  );
  assert.deepEqual(waveQuotaDecision({ isPlus: true, sentToday: 0, note: 'x'.repeat(140) }), { ok: true });
});

test('moderateText flags obvious spam and allows normal Spanish', () => {
  const ok = moderateText('Hola, ¿cómo estás? Quiero conocerte y tomar un café en Ñuñoa.');
  assert.equal(ok.flagged, false);
  assert.deepEqual(ok.categories, []);
  const spam = moderateText('Escríbeme a WhatsApp para ganar dinero fácil: https://ejemplo.cl');
  assert.equal(spam.flagged, true);
  assert.ok(spam.categories.includes('spam'));
  const abuse = moderateText('te voy a matar');
  assert.equal(abuse.flagged, true);
  assert.ok(abuse.categories.includes('abuse'));
});

test('webhook auth rejects bad credentials without loading firebase', () => {
  const loaded = Object.keys(require.cache).some((key) => (
    key.includes('firebase-admin') || key.includes('firebase-functions')
  ));
  assert.equal(loaded, false);
  assert.equal(webhookAuthError('Bearer wrong', 's3cret'), 'unauthorized');
  assert.equal(webhookAuthError(undefined, undefined), 'missing_secret');
  assert.equal(webhookAuthError('Bearer s3cret', ''), 'missing_secret');
  assert.equal(webhookAuthError('Bearer s3cret', 's3cret'), null);
  assert.equal(planFromRevenueCat({
    type: 'INITIAL_PURCHASE',
    entitlement_ids: ['plus'],
    expiration_at_ms: 1_800_000_000_000,
  }).plan, 'plus');
  assert.equal(planFromRevenueCat({ type: 'EXPIRATION', product_id: 'picaflor_plus' }).plan, 'free');
});

test('getNearby filter drops blocked, invisible, stale, and minor people', () => {
  const now = new Date('2026-10-06T12:00:00.000Z');
  const fresh = new Date(now.getTime() - 60_000);
  const adult = new Date(Date.UTC(1990, 0, 1));
  const base: NearbyCandidate = {
    uid: 'other',
    distanceMeters: 100,
    isVisible: true,
    locationUpdatedAt: fresh,
    birthDate: adult,
    blockedEitherWay: false,
    hasWave: false,
    lastActiveAt: fresh,
  };
  const run = (over: Partial<NearbyCandidate>) => filterNearbyPeople({
    callerUid: 'me',
    radiusMeters: 5000,
    now,
    candidates: [{ ...base, ...over }],
  });

  assert.equal(run({}).length, 1);
  assert.equal(run({})[0].distanceBucket, 'very_close');
  assert.equal(run({})[0].activityBucket, 'ahora');
  assert.deepEqual(run({ uid: 'me' }), []);
  assert.deepEqual(run({ blockedEitherWay: true }), []);
  assert.deepEqual(run({ isVisible: false }), []);
  assert.equal(run({ isVisible: false, hasWave: true }).length, 1);
  assert.deepEqual(run({
    locationUpdatedAt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000 - 1),
  }), []);
  assert.equal(run({
    locationUpdatedAt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
  }).length, 1);
  assert.deepEqual(run({ birthDate: null }), []);
  assert.deepEqual(run({ birthDate: new Date(Date.UTC(2010, 0, 1)) }), []);
  assert.deepEqual(run({ lastActiveAt: new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000) }), []);
  assert.deepEqual(run({ distanceMeters: 5001 }), []);
});

test('push and export shapes never carry coordinates or message text', () => {
  const secret = 'texto secreto del mensaje';
  const payload = messagePush('chat_1');
  assert.equal(JSON.stringify(payload).includes(secret), false);
  assert.equal(payload.notification.title, 'Nuevo mensaje en Picaflor');
  assert.equal(payload.notification.body, 'Tienes un mensaje nuevo.');
  assert.deepEqual(payload.data, { chatId: 'chat_1' });
  const exported = locationExport({
    geohash: '66j8xyz',
    latitude: -33.4,
    longitude: -70.6,
    updatedAt: '2026-10-06',
  });
  assert.deepEqual(exported, { geohash: '66j8xyz', updatedAt: '2026-10-06' });
  const user = withoutCoordinates({ email: 'a@b.c', latitude: 1, longitude: 2, settings: { latitude: 3 } });
  assert.deepEqual(user, { email: 'a@b.c', settings: {} });
});
