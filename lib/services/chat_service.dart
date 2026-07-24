import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../data/demo_store.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chats y mensajes (Firestore o [DemoStore]).
class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    bool? demoMode,
  }) : _isDemo = demoMode ?? AppConfig.demoMode {
    if (!_isDemo) {
      _db = firestore ?? FirebaseFirestore.instance;
    }
  }

  final bool _isDemo;
  FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db!.collection(AppConstants.chatsCollection);

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection(AppConstants.messagesSubcollection);

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
      return DemoStore.instance.getOrCreateChat(
        currentUid: currentUid,
        otherUid: otherUid,
      );
    }

    // Producción: chats demo no se crean en Firestore.
    if (otherUid.startsWith('demo_')) {
      return ChatModel(
        id: ChatModel.chatIdFor(currentUid, otherUid),
        participantIds: [currentUid, otherUid]..sort(),
        lastMessage: null,
        createdAt: DateTime.now(),
      );
    }

    final chatId = ChatModel.chatIdFor(currentUid, otherUid);
    final ref = _chats.doc(chatId);
    final snap = await ref.get();

    if (snap.exists && snap.data() != null) {
      return ChatModel.fromFirestore(snap);
    }

    final chat = ChatModel(
      id: chatId,
      participantIds: [currentUid, otherUid]..sort(),
    );

    await ref.set(chat.toCreateMap());
    return chat.copyWith(id: chatId);
  }

  Stream<List<ChatModel>> watchUserChats(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    if (_isDemo) return DemoStore.instance.watchUserChats(uid);

    return _chats
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ChatModel.fromFirestore(d)).toList(),
        )
        .handleError((e, st) {
      debugPrint('watchUserChats error: $e');
    });
  }

  Stream<ChatModel?> watchChat(String chatId) {
    if (chatId.isEmpty) return Stream.value(null);
    if (_isDemo) return DemoStore.instance.watchChat(chatId);
    return _chats.doc(chatId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ChatModel.fromFirestore(snap);
    });
  }

  Stream<List<MessageModel>> watchMessages(String chatId, {int limit = 80}) {
    if (chatId.isEmpty) return Stream.value(const []);
    if (_isDemo) return DemoStore.instance.watchMessages(chatId);

    if (chatId.contains('demo_')) {
      return Stream.value(const []);
    }

    return _messages(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MessageModel.fromFirestore(d, chatId: chatId))
          .toList();
      return list.reversed.toList();
    }).handleError((e) {
      debugPrint('watchMessages error: $e');
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

    final msgRef = _messages(chatId).doc();
    final message = MessageModel(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      text: trimmed,
    );

    try {
      final batch = _db!.batch();
      batch.set(msgRef, message.toCreateMap());
      // Nested map + FieldValue.increment (merge) actualiza unreadCount[uid].
      batch.set(
        _chats.doc(chatId),
        {
          'participantIds': [senderId, otherUid]..sort(),
          'lastMessage': trimmed,
          'lastMessageSenderId': senderId,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadCount': {
            otherUid: FieldValue.increment(1),
            senderId: 0,
          },
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return message.copyWith(createdAt: DateTime.now());
    } catch (e) {
      debugPrint('sendTextMessage error: $e');
      throw ChatException('No se pudo enviar el mensaje. Inténtalo de nuevo.');
    }
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
    try {
      await _chats.doc(chatId).set({
        'unreadCount': {uid: 0},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('markChatAsRead error: $e');
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    if (_isDemo) {
      final chats = await DemoStore.instance.watchChat(chatId).first;
      return chats;
    }
    final snap = await _chats.doc(chatId).get();
    if (!snap.exists || snap.data() == null) return null;
    return ChatModel.fromFirestore(snap);
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
