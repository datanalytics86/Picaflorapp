import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';

export function ensureAdmin(): void {
  if (getApps().length === 0) {
    initializeApp();
  }
}

export function db() {
  ensureAdmin();
  return getFirestore();
}

export function auth() {
  ensureAdmin();
  return getAuth();
}

export function messaging() {
  ensureAdmin();
  return getMessaging();
}

export function storageBucket() {
  ensureAdmin();
  return getStorage().bucket();
}
