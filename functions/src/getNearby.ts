import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import type { DocumentReference, DocumentSnapshot, Firestore } from 'firebase-admin/firestore';
import { db } from './admin';
import { toDate } from './coerce';
import { asRecord, callableOptions, invalid, requireUid } from './https';
import { parseBirthDate } from './pure/age';
import { capRadiusMeters, haversineMeters } from './pure/distance';
import { decodeGeohash, prefixRange, queryPrefixesFor } from './pure/geohash';
import { filterNearbyPeople, type NearbyCandidate } from './pure/nearbyFilter';
import { isPlusActive } from './pure/waveQuota';

const PER_PREFIX_LIMIT = 150;

async function getAllChunked(
  firestore: Firestore,
  refs: DocumentReference[],
): Promise<DocumentSnapshot[]> {
  const out: DocumentSnapshot[] = [];
  for (let i = 0; i < refs.length; i += 100) {
    const chunk = refs.slice(i, i + 100);
    if (chunk.length === 0) continue;
    const snaps = await firestore.getAll(...chunk);
    out.push(...snaps);
  }
  return out;
}

export const getNearby = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const body = asRecord(request.data);
  const requested = body.radiusMeters;
  if (typeof requested !== 'number' || !Number.isFinite(requested) || requested <= 0) {
    throw invalid('radiusMeters must be a positive number.');
  }

  const firestore = db();
  const now = new Date();
  const [locSnap, entSnap] = await Promise.all([
    firestore.doc(`locations/${uid}`).get(),
    firestore.doc(`entitlements/${uid}`).get(),
  ]);
  const callerHash = locSnap.get('geohash');
  if (typeof callerHash !== 'string') {
    throw invalid('Location is not set.');
  }
  const callerCenter = decodeGeohash(callerHash);
  if (!callerCenter) throw invalid('Location is not set.');

  const plus = isPlusActive(entSnap.get('plan'), toDate(entSnap.get('expiresAt')), now);
  const radiusMeters = capRadiusMeters(requested, plus);
  const prefixes = queryPrefixesFor(callerCenter.latitude, callerCenter.longitude);

  const snaps = await Promise.all(prefixes.map((prefix) => {
    const range = prefixRange(prefix);
    return firestore.collection('locations')
      .where('geohash', '>=', range.start)
      .where('geohash', '<=', range.end)
      .limit(PER_PREFIX_LIMIT)
      .get();
  }));

  const byUid = new Map<string, { geohash: string; updatedAt: unknown }>();
  for (const snap of snaps) {
    for (const doc of snap.docs) {
      const hash = doc.get('geohash');
      if (typeof hash === 'string') {
        byUid.set(doc.id, { geohash: hash, updatedAt: doc.get('updatedAt') });
      }
    }
  }
  byUid.delete(uid);

  const ids = [...byUid.keys()];
  if (ids.length === 0) {
    logger.info('getNearby.ok', { count: 0 });
    return { people: [] };
  }

  const [profiles, users, blockedByThem, wavesFrom, wavesTo, myBlocks] = await Promise.all([
    getAllChunked(firestore, ids.map((id) => firestore.doc(`profiles/${id}`))),
    getAllChunked(firestore, ids.map((id) => firestore.doc(`users/${id}`))),
    getAllChunked(firestore, ids.map((id) => firestore.doc(`blocks/${id}/blocked/${uid}`))),
    firestore.collection('waves').where('from', '==', uid).limit(500).get(),
    firestore.collection('waves').where('to', '==', uid).limit(500).get(),
    firestore.collection(`blocks/${uid}/blocked`).get(),
  ]);

  const waved = new Set<string>();
  for (const doc of wavesFrom.docs) {
    const to = doc.get('to');
    if (typeof to === 'string') waved.add(to);
  }
  for (const doc of wavesTo.docs) {
    const from = doc.get('from');
    if (typeof from === 'string') waved.add(from);
  }
  const blockedByMe = new Set(myBlocks.docs.map((doc) => doc.id));

  const candidates: NearbyCandidate[] = ids.map((id, index) => {
    const located = byUid.get(id);
    const center = located ? decodeGeohash(located.geohash) : null;
    const distanceMeters = center
      ? haversineMeters(
        callerCenter.latitude,
        callerCenter.longitude,
        center.latitude,
        center.longitude,
      )
      : Number.POSITIVE_INFINITY;
    const profile = profiles[index];
    const user = users[index];
    return {
      uid: id,
      distanceMeters,
      isVisible: profile?.get('isVisible') === true,
      locationUpdatedAt: toDate(located?.updatedAt),
      birthDate: parseBirthDate(user?.get('birthDate')),
      blockedEitherWay: blockedByMe.has(id) || blockedByThem[index]?.exists === true,
      hasWave: waved.has(id),
      lastActiveAt: toDate(user?.get('lastActiveAt')),
    };
  });

  const people = filterNearbyPeople({
    callerUid: uid,
    radiusMeters,
    now,
    candidates,
  });
  logger.info('getNearby.ok', { count: people.length });
  return { people };
});
