import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Conversación 1:1 entre dos usuarios de Picaflor.
class ChatModel extends Equatable {
  const ChatModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadCount = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;

  /// Mapa uid → cantidad de no leídos.
  final Map<String, int> unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// El otro participante respecto al usuario actual.
  String otherParticipantId(String currentUid) {
    return participantIds.firstWhere(
      (id) => id != currentUid,
      orElse: () => participantIds.isNotEmpty ? participantIds.first : '',
    );
  }

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  bool hasUnread(String uid) => unreadFor(uid) > 0;

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatModel.fromMap(data, id: doc.id);
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final unreadRaw = map['unreadCount'] as Map<String, dynamic>? ?? {};
    final unread = unreadRaw.map(
      (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
    );

    return ChatModel(
      id: id ?? map['id'] as String? ?? '',
      participantIds: (map['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageAt: _toDate(map['lastMessageAt']),
      unreadCount: unread,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        for (final id in participantIds) id: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ID determinístico de chat entre dos usuarios (ordenado).
  static String chatIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        participantIds,
        lastMessage,
        lastMessageSenderId,
        lastMessageAt,
        unreadCount,
        createdAt,
        updatedAt,
      ];
}
