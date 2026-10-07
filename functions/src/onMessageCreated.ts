import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, messaging } from './admin';
import { REGION } from './https';
import { moderateText } from './pure/moderate';
import { messagePush } from './pure/push';
import { fcmTokensFromUser } from './pure/tokens';

export const onMessageCreated = onDocumentCreated(
  {
    document: 'chats/{chatId}/messages/{messageId}',
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const senderId = snap.get('senderId');
    const chatId = event.params.chatId;
    if (typeof senderId !== 'string' || typeof chatId !== 'string' || senderId === 'deleted') return;

    const rawText = snap.get('text');
    let preview = 'Mensaje nuevo';
    if (typeof rawText === 'string') {
      if (moderateText(rawText).flagged) {
        preview = 'Mensaje eliminado';
        await snap.ref.update({ text: preview });
        logger.info('message.moderated');
      } else {
        preview = rawText.length > 140 ? `${rawText.slice(0, 140)}` : rawText;
      }
    }

    const chatRef = db().doc(`chats/${chatId}`);
    const chat = await chatRef.get();
    const participants = chat.get('participantIds');
    if (!Array.isArray(participants)) return;
    const recipients = participants.filter((id): id is string => (
      typeof id === 'string' && id !== senderId && id !== 'deleted'
    ));
    const patch: Record<string, unknown> = {
      lastMessage: preview,
      lastMessageSenderId: senderId,
      lastMessageAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    for (const recipient of recipients) {
      patch[`unreadCount.${recipient}`] = FieldValue.increment(1);
    }
    await chatRef.update(patch);

    const payload = messagePush(chatId);

    for (const recipient of recipients) {
      const user = await db().doc(`users/${recipient}`).get();
      const tokens = fcmTokensFromUser(user.data()).slice(0, 500);
      if (tokens.length === 0) continue;
      try {
        const result = await messaging().sendEachForMulticast({
          tokens,
          notification: payload.notification,
          data: payload.data,
        });
        logger.info('push.sent', {
          successCount: result.successCount,
          failureCount: result.failureCount,
        });
      } catch {
        logger.warn('push.failed');
      }
    }
  },
);
