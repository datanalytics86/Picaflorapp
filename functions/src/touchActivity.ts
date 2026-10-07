import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { db } from './admin';
import { callableOptions, requireUid } from './https';

export const touchActivity = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const firestore = db();
  const bucket = 'ahora';
  await firestore.doc(`users/${uid}`).set({
    lastActiveAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  await firestore.doc(`profiles/${uid}`).set({
    activityBucket: bucket,
  }, { merge: true });
  logger.info('touchActivity.ok');
  return { activityBucket: bucket };
});
