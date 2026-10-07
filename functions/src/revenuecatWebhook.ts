import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';
import { db } from './admin';
import { REGION } from './https';
import { planFromRevenueCat, revenueCatAppUserId, revenueCatEventId, type RevenueCatEvent } from './pure/revenuecat';
import { webhookAuthError } from './pure/webhookAuth';

export const revenuecatWebhook = onRequest(
  { region: REGION, invoker: 'public', cors: false },
  async (req, res) => {
    const authError = webhookAuthError(
      req.get('authorization'),
      process.env.REVENUECAT_WEBHOOK_SECRET,
    );
    if (authError) {
      res.status(401).send('unauthorized');
      return;
    }
    if (req.method !== 'POST') {
      res.status(405).send('method not allowed');
      return;
    }

    const body = req.body as { event?: RevenueCatEvent } | undefined;
    const event = body && typeof body === 'object' ? body.event : undefined;
    if (!event || typeof event !== 'object') {
      res.status(400).json({ ok: false });
      return;
    }
    const eventId = revenueCatEventId(event);
    const appUserId = revenueCatAppUserId(event);
    if (!eventId || !appUserId) {
      res.status(400).json({ ok: false });
      return;
    }

    const { plan, expiresAtMs } = planFromRevenueCat(event);
    const firestore = db();
    const eventRef = firestore.doc(`webhookEvents/${eventId}`);
    const entRef = firestore.doc(`entitlements/${appUserId}`);
    const duplicate = await firestore.runTransaction(async (tx) => {
      const existing = await tx.get(eventRef);
      if (existing.exists) return true;
      tx.set(entRef, {
        plan,
        expiresAt: expiresAtMs == null ? null : Timestamp.fromMillis(expiresAtMs),
        source: 'revenuecat',
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      tx.set(eventRef, {
        source: 'revenuecat',
        type: typeof event.type === 'string' ? event.type.slice(0, 80) : null,
        processedAt: FieldValue.serverTimestamp(),
      });
      return false;
    });

    logger.info('revenuecatWebhook.ok', { duplicate, plan });
    res.status(200).json({ ok: true, duplicate });
  },
);
