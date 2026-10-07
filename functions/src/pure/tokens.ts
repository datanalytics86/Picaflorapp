export function fcmTokensFromUser(data: Record<string, unknown> | undefined): string[] {
  if (!data) return [];
  const out = new Set<string>();
  const add = (token: unknown) => {
    if (typeof token === 'string' && token.length > 0 && token.length < 4096) out.add(token);
  };
  const raw = data.fcmTokens;
  if (Array.isArray(raw)) {
    for (const token of raw) add(token);
  } else if (raw && typeof raw === 'object') {
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (value === true || (value != null && typeof value === 'object')) add(key);
      else add(value);
    }
  }
  add(data.fcmToken);
  return [...out];
}
