import { FieldValue, Timestamp, type UpdateData } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db } from './admin';
import { toDate } from './coerce';
import { asRecord, callableOptions, invalid, requireUid } from './https';
import { assertLatLon } from './pure/grid';
import { storedGeohash } from './pure/geohash';
import { locationUpdateAllowed } from './pure/rateLimit';

export const updateLocation = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const body = asRecord(request.data);
  let latitude: number;
  let longitude: number;
  try {
    ({ latitude, longitude } = assertLatLon(body.latitude, body.longitude));
  } catch {
    throw invalid('latitude and longitude must be valid numbers.');
  }

  const geohash = storedGeohash(latitude, longitude);
  const now = new Date();
  const firestore = db();
  const locRef = firestore.doc(`locations/${uid}`);
  const userRef = firestore.doc(`users/${uid}`);

  await firestore.runTransaction(async (tx) => {
    const loc = await tx.get(locRef);
    const previous = loc.exists ? toDate(loc.get('updatedAt')) : null;
    if (!locationUpdateAllowed(previous, now)) {
      throw new HttpsError('resource-exhausted', 'Location can be updated every 20 seconds.');
    }
    tx.set(locRef, {
      geohash,
      updatedAt: Timestamp.fromDate(now),
    });
    const user = await tx.get(userRef);
    if (user.exists) {
      const data = user.data() ?? {};
      const patch: UpdateData<Record<string, unknown>> = {};
      if ('latitude' in data) patch.latitude = FieldValue.delete();
      if ('longitude' in data) patch.longitude = FieldValue.delete();
      if ('isOnline' in data) patch.isOnline = FieldValue.delete();
      if (Object.keys(patch).length > 0) tx.update(userRef, patch);
    }
  });

  logger.info('updateLocation.ok');
  return { ok: true };
});
