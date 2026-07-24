import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Usuario de Picaflor.
class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio = '',
    this.interests = const [],
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.isVisible = true,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.fcmToken,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final List<String> interests;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final bool isVisible;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;

  bool get hasLocation => latitude != null && longitude != null;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(data, uid: doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Usuario',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String? ?? '',
      interests: (map['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isOnline: map['isOnline'] as bool? ?? false,
      isVisible: map['isVisible'] as bool? ?? true,
      lastSeen: _toDate(map['lastSeen']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
      'isVisible': isVisible,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fcmToken': fcmToken,
    };
  }

  /// Mapa para crear el doc en Firestore (usa server timestamps).
  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': true,
      'isVisible': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    double? latitude,
    double? longitude,
    bool? isOnline,
    bool? isVisible,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    bool clearPhoto = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      isVisible: isVisible ?? this.isVisible,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
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
        uid,
        email,
        displayName,
        photoUrl,
        bio,
        interests,
        latitude,
        longitude,
        isOnline,
        isVisible,
        lastSeen,
        createdAt,
        updatedAt,
        fcmToken,
      ];
}
