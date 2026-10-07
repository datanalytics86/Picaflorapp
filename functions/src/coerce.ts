export function toDate(value: unknown): Date | null {
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (value && typeof value === 'object' && 'toDate' in value) {
    const toDateFn = (value as { toDate: () => Date }).toDate;
    if (typeof toDateFn === 'function') {
      const date = toDateFn.call(value);
      if (date instanceof Date && !Number.isNaN(date.getTime())) return date;
    }
  }
  return null;
}
