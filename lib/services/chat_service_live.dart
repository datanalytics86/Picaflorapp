import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'chat_service.dart';

FirebaseFirestore get _db => FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> get _chats =>
    _db.collection(AppConstants.chatsCollection);

CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
    _chats.doc(chatId).collection(AppConstants.messagesSubcollection);

Future<ChatModel> getOrCreateChat({
  required String currentUid,
  required String otherUid,
}) async {
  final chatId = ChatModel.chatIdFor(currentUid, otherUid);
  final ref = _chats.doc(chatId);
  final snap = await ref.get();

  if (snap.exists && snap.data() != null) {
    return ChatModel.fromMap(snap.data()!, id: snap.id);
  }

  final chat = ChatModel(
    id: chatId,
    participantIds: [currentUid, otherUid]..sort(),
  );

  await ref.set({
    ...chat.toCreateMap(),
    'lastMessageAt': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  return chat.copyWith(id: chatId);
}

Stream<List<ChatModel>> watchUserChats(String uid) {
  return _chats
      .where('participantIds', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => ChatModel.fromMap(d.data(), id: d.id))
            .toList(),
      )
      .handleError((e, st) {
    debugPrint('watchUserChats error: $e');
  });
}

Stream<ChatModel?> watchChat(String chatId) {
  return _chats.doc(chatId).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return ChatModel.fromMap(snap.data()!, id: snap.id);
  });
}

Stream<List<MessageModel>> watchMessages(String chatId, {int limit = 80}) {
  if (chatId.contains('demo_')) {
    return Stream.value(const []);
  }

  return _messages(chatId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) {
    final list = snap.docs
        .map((d) => MessageModel.fromMap(d.data(), id: d.id, chatId: chatId))
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
  final msgRef = _messages(chatId).doc();
  final message = MessageModel(
    id: msgRef.id,
    chatId: chatId,
    senderId: senderId,
    text: text,
  );

  try {
    final batch = _db.batch();
    batch.set(msgRef, {
      ...message.toCreateMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _chats.doc(chatId),
      {
        'participantIds': [senderId, otherUid]..sort(),
        'lastMessage': text,
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
  final snap = await _chats.doc(chatId).get();
  if (!snap.exists || snap.data() == null) return null;
  return ChatModel.fromMap(snap.data()!, id: snap.id);
}
