const SPAM = [
  'whatsapp',
  'wa.me',
  't.me/',
  'telegram',
  'onlyfans',
  'only fans',
  'bitcoin',
  'cripto',
  'crypto',
  'gana dinero',
  'dinero facil',
  'trabajo desde casa',
  'clave bancaria',
  'envia tu clave',
  'ingresa tu clave',
  'inversion garantizada',
  'haz clic',
  'http://',
  'https://',
  'www.',
  'te ganaste',
  'reclama tu premio',
];

const ABUSE = [
  'te voy a matar',
  'matate',
  'conchetumare',
  'hijo de puta',
  'te voy a violar',
];

export function normalizeForModeration(input: string): string {
  return input
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

export function moderateText(input: string): { flagged: boolean; categories: Array<'spam' | 'abuse'> } {
  const normalized = normalizeForModeration(input);
  const categories: Array<'spam' | 'abuse'> = [];
  if (SPAM.some((phrase) => normalized.includes(normalizeForModeration(phrase)))) {
    categories.push('spam');
  }
  if (ABUSE.some((phrase) => normalized.includes(normalizeForModeration(phrase)))) {
    categories.push('abuse');
  }
  return { flagged: categories.length > 0, categories };
}
