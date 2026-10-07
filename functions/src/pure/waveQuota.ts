export const FREE_DAILY_WAVE_LIMIT = 20;
export const NOTE_MAX_LENGTH = 140;

const SANTIAGO = 'America/Santiago';

export function santiagoDateKey(date: Date): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: SANTIAGO,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

function santiagoClock(date: Date): { hour: number; minute: number; second: number } {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: SANTIAGO,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const read = (type: string) => Number(parts.find((part) => part.type === type)?.value ?? '0');
  return { hour: read('hour'), minute: read('minute'), second: read('second') };
}

/** UTC instant of local midnight for the Santiago calendar day that contains `now`. */
export function startOfSantiagoDay(now: Date): Date {
  const clock = santiagoClock(now);
  const elapsed = ((clock.hour * 60 + clock.minute) * 60 + clock.second) * 1000 + now.getMilliseconds();
  return new Date(now.getTime() - elapsed);
}

export function isPlusActive(
  plan: unknown,
  expiresAt: Date | null,
  now: Date,
): boolean {
  return plan === 'plus' && expiresAt != null && expiresAt.getTime() > now.getTime();
}

export function countWavesOnSantiagoDay(createdAts: Date[], now: Date): number {
  const key = santiagoDateKey(now);
  return createdAts.reduce((count, created) => (
    santiagoDateKey(created) === key ? count + 1 : count
  ), 0);
}

export interface WaveQuotaInput {
  isPlus: boolean;
  sentToday: number;
  note: string | null;
}

export type WaveQuotaDecision =
  | { ok: true }
  | { ok: false; reason: 'note_requires_plus' | 'note_too_long' | 'daily_limit' };

export function waveQuotaDecision(input: WaveQuotaInput): WaveQuotaDecision {
  if (input.note != null && input.note.length > 0) {
    if (!input.isPlus) return { ok: false, reason: 'note_requires_plus' };
    if (input.note.length > NOTE_MAX_LENGTH) return { ok: false, reason: 'note_too_long' };
  }
  if (!input.isPlus && input.sentToday >= FREE_DAILY_WAVE_LIMIT) {
    return { ok: false, reason: 'daily_limit' };
  }
  return { ok: true };
}
