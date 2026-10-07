import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { db } from './admin';
import { asRecord, callableOptions, invalid, requireUid } from './https';
import { chatIdFor } from './pure/chat';

export const blockUser = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const otherUid = asRecord(request.data).otherUid;
  if (typeof otherUid !== 'string' || otherUid.length < 1 || otherUid.length > 128 || otherUid === uid) {
    throw invalid('Invalid user.');
  }
  const firestore = db();
  await firestore.doc(`blocks/${uid}/blocked/${otherUid}`).set({
    createdAt: FieldValue.serverTimestamp(),
  });
  const chatRef = firestore.doc(`chats/${chatIdFor(uid, otherUid)}`);
  const chat = await chatRef.get();
  if (chat.exists) {
    await chatRef.update({
      status: 'blocked',
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  logger.info('blockUser.ok');
  return { ok: true };
});
