export interface RevenueCatEvent {
  id?: unknown;
  type?: unknown;
  app_user_id?: unknown;
  product_id?: unknown;
  entitlement_ids?: unknown;
  expiration_at_ms?: unknown;
}

const END_ACCESS = new Set(['EXPIRATION']);

export function planFromRevenueCat(event: RevenueCatEvent): {
  plan: 'plus' | 'free';
  expiresAtMs: number | null;
} {
  const expiresAtMs = typeof event.expiration_at_ms === 'number' && Number.isFinite(event.expiration_at_ms)
    ? event.expiration_at_ms
    : null;
  const type = typeof event.type === 'string' ? event.type : '';
  if (END_ACCESS.has(type)) return { plan: 'free', expiresAtMs };
  const ids = Array.isArray(event.entitlement_ids)
    ? event.entitlement_ids.filter((id): id is string => typeof id === 'string').map((id) => id.toLowerCase())
    : [];
  const product = typeof event.product_id === 'string' ? event.product_id.toLowerCase() : '';
  const plus = ids.includes('plus') || product.includes('plus');
  return { plan: plus ? 'plus' : 'free', expiresAtMs };
}

export function revenueCatEventId(event: RevenueCatEvent): string | null {
  if (typeof event.id !== 'string') return null;
  const id = event.id.trim();
  if (id.length < 1 || id.length > 200) return null;
  if (/[/@\s]/.test(id)) return null;
  return id;
}

export function revenueCatAppUserId(event: RevenueCatEvent): string | null {
  if (typeof event.app_user_id !== 'string') return null;
  const uid = event.app_user_id.trim();
  if (uid.length < 1 || uid.length > 128) return null;
  if (uid.includes('/') || uid.includes('@')) return null;
  return uid;
}
