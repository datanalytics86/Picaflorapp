export function chatIdFor(uidA: string, uidB: string): string {
  return [uidA, uidB].sort().join('_');
}

export function confirmAccountDeletion(value: unknown): boolean {
  return value === 'ELIMINAR';
}
