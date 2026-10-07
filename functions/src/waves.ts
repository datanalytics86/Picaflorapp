import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db } from './admin';
import { toDate } from './coerce';
import { asRecord, callableOptions, invalid, requireUid } from './https';
import { chatIdFor } from './pure/chat';
import { moderateText } from './pure/moderate';
import {
  countWavesOnSantiagoDay,
  isPlusActive,
  startOfSantiagoDay,
  waveQuotaDecision,
} from './pure/waveQuota';

async function blocked(firestore: Firestore, uid: string, other: string): Promise<boolean> {
  const [a, b] = await Promise.all([
    firestore.doc(`blocks/${uid}/blocked/${other}`).get(),
    firestore.doc(`blocks/${other}/blocked/${uid}`).get(),
  ]);
  return a.exists || b.exists;
}

export const sendWave = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const body = asRecord(request.data);
  const toUid = body.toUid;
  if (typeof toUid !== 'string' || toUid.length < 1 || toUid.length > 128 || toUid === uid) {
    throw invalid('Invalid recipient.');
  }
  let note: string | null = null;
  if (body.note != null && body.note !== '') {
    if (typeof body.note !== 'string') throw invalid('Invalid note.');
    note = body.note;
  }
  if (note && moderateText(note).flagged) {
    throw new HttpsError('failed-precondition', 'Note was rejected.');
  }

  const firestore = db();
  const now = new Date();
  if (await blocked(firestore, uid, toUid)) {
    throw new HttpsError('permission-denied', 'Cannot wave this person.');
  }

  const ent = await firestore.doc(`entitlements/${uid}`).get();
  const plus = isPlusActive(ent.get('plan'), toDate(ent.get('expiresAt')), now);
  const since = Timestamp.fromDate(startOfSantiagoDay(now));
  const [todaySnap, pendingSnap] = await Promise.all([
    firestore.collection('waves').where('from', '==', uid).where('createdAt', '>=', since).get(),
    firestore.collection('waves')
      .where('from', '==', uid)
      .where('to', '==', toUid)
      .where('status', '==', 'pending')
      .limit(1)
      .get(),
  ]);
  if (!pendingSnap.empty) {
    throw new HttpsError('already-exists', 'A pending wave already exists.');
  }
  const sentToday = countWavesOnSantiagoDay(
    todaySnap.docs.map((doc) => toDate(doc.get('createdAt'))).filter((date): date is Date => date != null),
    now,
  );
  const quota = waveQuotaDecision({ isPlus: plus, sentToday, note });
  if (!quota.ok) {
    throw new HttpsError(
      quota.reason === 'daily_limit' ? 'resource-exhausted' : 'permission-denied',
      'Wave was rejected.',
    );
  }

  const ref = firestore.collection('waves').doc();
  const payload: Record<string, unknown> = {
    from: uid,
    to: toUid,
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  };
  if (note) payload.note = note;
  await ref.set(payload);
  logger.info('sendWave.ok');
  return { waveId: ref.id, status: 'pending' };
});

export const respondWave = onCall(callableOptions, async (request) => {
  const uid = requireUid(request);
  const body = asRecord(request.data);
  const waveId = body.waveId;
  if (typeof waveId !== 'string' || waveId.length < 1 || waveId.length > 200) {
    throw invalid('Invalid wave.');
  }
  if (typeof body.accept !== 'boolean') throw invalid('accept must be a boolean.');
  const accept = body.accept;

  const firestore = db();
  const waveRef = firestore.doc(`waves/${waveId}`);
  const result = await firestore.runTransaction(async (tx) => {
    const wave = await tx.get(waveRef);
    if (!wave.exists) throw new HttpsError('not-found', 'Wave not found.');
    if (wave.get('to') !== uid) throw new HttpsError('permission-denied', 'Only the recipient can respond.');
    if (wave.get('status') !== 'pending') {
      throw new HttpsError('failed-precondition', 'Wave is not pending.');
    }
    const from = wave.get('from');
    if (typeof from !== 'string' || from.length === 0 || from === uid) {
      throw new HttpsError('failed-precondition', 'Wave is invalid.');
    }
    if (!accept) {
      tx.update(waveRef, {
        status: 'ignored',
        respondedAt: FieldValue.serverTimestamp(),
      });
      return { ok: true as const, status: 'ignored' as const };
    }
    const blockedByRecipient = await tx.get(firestore.doc(`blocks/${uid}/blocked/${from}`));
    const blockedBySender = await tx.get(firestore.doc(`blocks/${from}/blocked/${uid}`));
    if (blockedByRecipient.exists || blockedBySender.exists) {
      throw new HttpsError('permission-denied', 'Cannot respond while blocked.');
    }
    const chatId = chatIdFor(uid, from);
    const chatRef = firestore.doc(`chats/${chatId}`);
    const chat = await tx.get(chatRef);
    tx.update(waveRef, {
      status: 'accepted',
      respondedAt: FieldValue.serverTimestamp(),
    });
    if (!chat.exists) {
      const participantIds = [uid, from].sort();
      tx.set(chatRef, {
        participantIds,
        status: 'active',
        unreadCount: { [participantIds[0]]: 0, [participantIds[1]]: 0 },
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return { ok: true as const, status: 'accepted' as const, chatId };
  });
  logger.info('respondWave.ok', { status: result.status });
  return result;
});
