import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { db } from './admin';
import { callableOptions, requireUid } from './https';
import { locationExport, withoutCoordinates } from './pure/exportShape';

export const exportMyData = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const firestore = db();
  const [user, profile, location, ent, wavesFrom, wavesTo, blocks, chats] = await Promise.all([
    firestore.doc(`users/${uid}`).get(),
    firestore.doc(`profiles/${uid}`).get(),
    firestore.doc(`locations/${uid}`).get(),
    firestore.doc(`entitlements/${uid}`).get(),
    firestore.collection('waves').where('from', '==', uid).get(),
    firestore.collection('waves').where('to', '==', uid).get(),
    firestore.collection(`blocks/${uid}/blocked`).get(),
    firestore.collection('chats').where('participantIds', 'array-contains', uid).get(),
  ]);

  const chatExports = [];
  for (const chat of chats.docs) {
    const messages = await chat.ref.collection('messages').where('senderId', '==', uid).get();
    chatExports.push({
      id: chat.id,
      messages: messages.docs.map((doc) => withoutCoordinates({ id: doc.id, ...doc.data() })),
    });
  }

  logger.info('exportMyData.ok', { chats: chatExports.length });
  return {
    user: user.exists ? withoutCoordinates(user.data() ?? {}) : null,
    profile: profile.exists ? withoutCoordinates(profile.data() ?? {}) : null,
    location: locationExport(location.data()),
    waves: [...wavesFrom.docs, ...wavesTo.docs].map((doc) => (
      withoutCoordinates({ id: doc.id, ...doc.data() })
    )),
    blocks: blocks.docs.map((doc) => doc.id),
    entitlements: ent.exists ? withoutCoordinates(ent.data() ?? {}) : null,
    chats: chatExports,
  };
});
