import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

/// Mensaje individual dentro de un chat.
class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.imageUrl,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final MessageType type;
  final String? imageUrl;
  final bool isRead;
  final DateTime? createdAt;

  bool get isSystem => type == MessageType.system;
  bool get hasImage => type == MessageType.image && imageUrl != null;

  bool isMine(String currentUid) => senderId == currentUid;

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String chatId,
  }) {
    final data = doc.data() ?? {};
    return MessageModel.fromMap(data, id: doc.id, chatId: chatId);
  }

  factory MessageModel.fromMap(
    Map<String, dynamic> map, {
    String? id,
    String? chatId,
  }) {
    return MessageModel(
      id: id ?? map['id'] as String? ?? '',
      chatId: chatId ?? map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: _typeFromString(map['type'] as String?),
      imageUrl: map['imageUrl'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'imageUrl': imageUrl,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static MessageType _typeFromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props =>
      [id, chatId, senderId, text, type, imageUrl, isRead, createdAt];
}
