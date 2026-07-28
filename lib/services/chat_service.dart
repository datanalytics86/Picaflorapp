import '../core/config/app_config.dart';
import '../data/demo_store.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

import 'chat_service_live.dart' deferred as live;

/// Chats y mensajes.
///
/// DEMO: [DemoStore] — sin cloud_firestore en el bundle de arranque.
class ChatService {
  ChatService({bool? demoMode}) : _isDemo = demoMode ?? AppConfig.demoMode;

  final bool _isDemo;
  bool _liveLoaded = false;

  Future<void> _ensureLive() async {
    if (_isDemo) throw StateError('Chat live no se carga en DEMO');
    if (_liveLoaded) return;
    await live.loadLibrary().timeout(const Duration(seconds: 6));
    _liveLoaded = true;
  }

  Future<ChatModel> getOrCreateChat({
    required String currentUid,
    required String otherUid,
  }) async {
    if (currentUid.isEmpty || otherUid.isEmpty) {
      throw ChatException('No se pudo abrir el chat.');
    }
    if (currentUid == otherUid) {
      throw ChatException('No puedes chatear contigo mismo.');
    }

    if (_isDemo) {
      // Local, inmediato (sin micro-delays).
      return DemoStore.instance.getOrCreateChat(
        currentUid: currentUid,
        otherUid: otherUid,
      );
    }

    if (otherUid.startsWith('demo_')) {
      return ChatModel(
        id: ChatModel.chatIdFor(currentUid, otherUid),
        participantIds: [currentUid, otherUid]..sort(),
        lastMessage: null,
        createdAt: DateTime.now(),
      );
    }

    await _ensureLive();
    return live.getOrCreateChat(
      currentUid: currentUid,
      otherUid: otherUid,
    );
  }

  Stream<List<ChatModel>> watchUserChats(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    if (_isDemo) return DemoStore.instance.watchUserChats(uid);
    return Stream.multi((listener) async {
      try {
        await _ensureLive();
        final sub = live.watchUserChats(uid).listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = () => sub.cancel();
      } catch (e) {
        listener.addError(e);
        listener.close();
      }
    });
  }

  Stream<ChatModel?> watchChat(String chatId) {
    if (chatId.isEmpty) return Stream.value(null);
    if (_isDemo) return DemoStore.instance.watchChat(chatId);
    return Stream.multi((listener) async {
      try {
        await _ensureLive();
        final sub = live.watchChat(chatId).listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = () => sub.cancel();
      } catch (e) {
        listener.addError(e);
        listener.close();
      }
    });
  }

  Stream<List<MessageModel>> watchMessages(String chatId, {int limit = 80}) {
    if (chatId.isEmpty) return Stream.value(const []);
    if (_isDemo) return DemoStore.instance.watchMessages(chatId);
    return Stream.multi((listener) async {
      try {
        await _ensureLive();
        final sub = live.watchMessages(chatId, limit: limit).listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = () => sub.cancel();
      } catch (e) {
        listener.addError(e);
        listener.close();
      }
    });
  }

  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String otherUid,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ChatException('Escribe algo antes de enviar.');
    }

    if (_isDemo) {
      return DemoStore.instance.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        text: trimmed,
        otherUid: otherUid,
      );
    }

    if (otherUid.startsWith('demo_') || chatId.contains('demo_')) {
      throw ChatException(
        'Este perfil es de ejemplo. Cuando haya gente real, el chat funciona altiro.',
      );
    }

    await _ensureLive();
    return live.sendTextMessage(
      chatId: chatId,
      senderId: senderId,
      text: trimmed,
      otherUid: otherUid,
    );
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String uid,
  }) async {
    if (_isDemo) {
      await DemoStore.instance.markChatAsRead(chatId: chatId, uid: uid);
      return;
    }
    if (chatId.contains('demo_')) return;
    await _ensureLive();
    await live.markChatAsRead(chatId: chatId, uid: uid);
  }

  Future<ChatModel?> getChat(String chatId) async {
    if (_isDemo) {
      return DemoStore.instance.watchChat(chatId).first;
    }
    await _ensureLive();
    return live.getChat(chatId);
  }

  Stream<int> watchTotalUnread(String uid) {
    if (_isDemo) return DemoStore.instance.watchTotalUnread(uid);
    return watchUserChats(uid).map((chats) {
      var total = 0;
      for (final c in chats) {
        total += c.unreadFor(uid);
      }
      return total;
    });
  }
}

class ChatException implements Exception {
  ChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
