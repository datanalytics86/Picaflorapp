import type { DocumentReference } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { auth, db, storageBucket } from './admin';
import { asRecord, callableOptions, invalid, requireUid } from './https';
import { confirmAccountDeletion } from './pure/chat';

async function commitDeletes(refs: DocumentReference[]): Promise<void> {
  if (refs.length === 0) return;
  const firestore = refs[0].firestore;
  for (let i = 0; i < refs.length; i += 400) {
    const batch = firestore.batch();
    for (const ref of refs.slice(i, i + 400)) batch.delete(ref);
    await batch.commit();
  }
}

async function anonymizeOwnMessages(firestore: FirebaseFirestore.Firestore, uid: string): Promise<void> {
  const chats = await firestore.collection('chats').where('participantIds', 'array-contains', uid).get();
  const refs: DocumentReference[] = [];
  for (const chat of chats.docs) {
    const messages = await chat.ref.collection('messages').where('senderId', '==', uid).get();
    refs.push(...messages.docs.map((doc) => doc.ref));
  }
  for (let i = 0; i < refs.length; i += 400) {
    const batch = firestore.batch();
    for (const ref of refs.slice(i, i + 400)) {
      batch.update(ref, { senderId: 'deleted', text: 'Mensaje eliminado' });
    }
    await batch.commit();
  }
}

export const deleteAccount = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  if (!confirmAccountDeletion(asRecord(request.data).confirm)) {
    throw invalid('Confirmation required.');
  }
  const firestore = db();
  await anonymizeOwnMessages(firestore, uid);

  const [waves, blocks] = await Promise.all([
    firestore.collection('waves').where('from', '==', uid).get(),
    firestore.collection(`blocks/${uid}/blocked`).get(),
  ]);
  await commitDeletes([
    ...waves.docs.map((doc) => doc.ref),
    ...blocks.docs.map((doc) => doc.ref),
    firestore.doc(`users/${uid}`),
    firestore.doc(`profiles/${uid}`),
    firestore.doc(`locations/${uid}`),
    firestore.doc(`entitlements/${uid}`),
    firestore.doc(`blocks/${uid}`),
  ]);

  try {
    await storageBucket().deleteFiles({ prefix: `avatars/${uid}/` });
  } catch {
    logger.info('deleteAccount.storageSkipped');
  }

  try {
    await auth().deleteUser(uid);
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code !== 'auth/user-not-found') throw error;
  }

  logger.info('deleteAccount.ok');
  return { ok: true, purgeWithinDays: 30 };
});
