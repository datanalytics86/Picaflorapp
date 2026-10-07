import { readFileSync } from 'node:fs';
import path from 'node:path';
import { after, before, beforeEach, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(path.join(here, '..', 'firestore.rules'), 'utf8');

let env: RulesTestEnvironment;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'picaflor-rules',
    firestore: { rules },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

async function seed(): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), { email: 'alice@example.com', birthDate: '1990-01-01' });
    await setDoc(doc(db, 'users/bob'), { email: 'bob@example.com', birthDate: '1991-02-02' });
    await setDoc(doc(db, 'profiles/bob'), {
      displayName: 'Bob',
      bio: 'Hola',
      interests: ['cafe'],
      photoUrl: null,
      isVisible: true,
    });
    await setDoc(doc(db, 'locations/bob'), { geohash: '66j8abc', updatedAt: new Date() });
    await setDoc(doc(db, 'chats/alice_bob'), {
      participantIds: ['alice', 'bob'],
      status: 'active',
      unreadCount: { alice: 0, bob: 0 },
    });
    await setDoc(doc(db, 'chats/alice_cara'), {
      participantIds: ['alice', 'cara'],
      status: 'blocked',
      unreadCount: { alice: 0, cara: 0 },
    });
    await setDoc(doc(db, 'entitlements/alice'), { plan: 'free', source: 'revenuecat' });
  });
}

test('stranger cannot read locations', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(getDoc(doc(alice, 'locations/bob')));
});

test('stranger cannot read another user email', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(getDoc(doc(alice, 'users/bob')));
});

test('owner can read their own user doc', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(alice, 'users/alice')));
});

test('signed-in user can read a profile when nobody is blocked', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(alice, 'profiles/bob')));
});

test('participant cannot change participantIds', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(updateDoc(doc(alice, 'chats/alice_bob'), {
    participantIds: ['alice', 'mallory'],
  }));
});

test('non-participant cannot create messages', async () => {
  await seed();
  const mallory = env.authenticatedContext('mallory').firestore();
  await assertFails(setDoc(doc(mallory, 'chats/alice_bob/messages/m1'), {
    senderId: 'mallory',
    text: 'hola',
  }));
});

test('blocked chat cannot create messages', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(alice, 'chats/alice_cara/messages/m1'), {
    senderId: 'alice',
    text: 'hola',
  }));
});

test('active participant can create a message', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(alice, 'chats/alice_bob/messages/m1'), {
    senderId: 'alice',
    text: 'hola',
  }));
});

test('nobody can write entitlements from the client', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(alice, 'entitlements/alice'), { plan: 'plus' }));
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(anon, 'entitlements/bob'), { plan: 'plus' }));
});

test('reports can be created but not read', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(alice, 'reports/r1'), {
    reporterId: 'alice',
    reason: 'spam',
    text: 'cuenta falsa',
  }));
  await assertFails(getDoc(doc(alice, 'reports/r1')));
});

test('client cannot write locations', async () => {
  await seed();
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(alice, 'locations/alice'), {
    geohash: '66j8xyz',
    updatedAt: new Date(),
  }));
});
