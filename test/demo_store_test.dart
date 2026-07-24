import 'package:flutter_test/flutter_test.dart';
import 'package:picaflorapp/core/config/app_config.dart';
import 'package:picaflorapp/data/demo_store.dart';

void main() {
  test('demo store: sesión, nearby y chat en memoria', () async {
    expect(AppConfig.demoMode, isTrue);

    final store = DemoStore.instance;
    final me = await store.signInDemo();
    expect(me.uid, AppConfig.demoUid);
    expect(store.currentUid, AppConfig.demoUid);

    final chat = await store.getOrCreateChat(
      currentUid: me.uid,
      otherUid: 'demo_matias',
    );
    expect(chat.participantIds, contains(me.uid));
    expect(chat.participantIds, contains('demo_matias'));

    final sent = await store.sendTextMessage(
      chatId: chat.id,
      senderId: me.uid,
      text: 'Hola demo',
      otherUid: 'demo_matias',
    );
    expect(sent.text, 'Hola demo');

    final messages = await store.watchMessages(chat.id).first;
    expect(messages.any((m) => m.text == 'Hola demo'), isTrue);

    await store.signOut();
    expect(store.currentUid, isNull);
  });
}
