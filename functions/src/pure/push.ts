export const MESSAGE_PUSH_TITLE = 'Nuevo mensaje en Picaflor';
export const MESSAGE_PUSH_BODY = 'Tienes un mensaje nuevo.';

/** Data is chatId only. The notification copy never includes message text. */
export function messagePush(chatId: string): {
  notification: { title: string; body: string };
  data: { chatId: string };
} {
  return {
    notification: { title: MESSAGE_PUSH_TITLE, body: MESSAGE_PUSH_BODY },
    data: { chatId },
  };
}
