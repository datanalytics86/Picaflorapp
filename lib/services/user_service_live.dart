import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/utils/distance_utils.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Implementación Firestore — solo se carga con deferred (no DEMO).
FirebaseFirestore get _db => FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> get _users =>
    _db.collection(AppConstants.usersCollection);

Future<void> createUser(UserModel user) async {
  await _users.doc(user.uid).set({
    ...user.toCreateMap(),
    'lastSeen': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<UserModel?> getUser(String uid) async {
  try {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!, uid: snap.id);
  } catch (e) {
    debugPrint('getUser error: $e');
    return null;
  }
}

Stream<UserModel?> watchUser(String uid) {
  return _users.doc(uid).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!, uid: snap.id);
  }).handleError((e) {
    debugPrint('watchUser error: $e');
  });
}

Future<void> updateUser(String uid, Map<String, dynamic> data) async {
  await _users.doc(uid).set({
    ...data,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> updateProfile({
  required String uid,
  String? displayName,
  String? bio,
  String? photoUrl,
  List<String>? interests,
  bool? isVisible,
}) async {
  final data = <String, dynamic>{
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (displayName != null) data['displayName'] = displayName.trim();
  if (bio != null) data['bio'] = bio.trim();
  if (photoUrl != null) data['photoUrl'] = photoUrl;
  if (interests != null) data['interests'] = interests;
  if (isVisible != null) data['isVisible'] = isVisible;
  await _users.doc(uid).set(data, SetOptions(merge: true));
}

Future<void> updateLocation({
  required String uid,
  required double latitude,
  required double longitude,
}) async {
  await _users.doc(uid).set({
    'latitude': latitude,
    'longitude': longitude,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastSeen': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> setOnlineStatus(String uid, bool isOnline) async {
  await _users.doc(uid).set({
    'isOnline': isOnline,
    'lastSeen': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<List<NearbyUser>> getNearbyUsers({
  required String currentUid,
  required double latitude,
  required double longitude,
  double radiusMeters = SantiagoBounds.defaultSearchRadiusMeters,
  int limit = 50,
}) async {
  final latDelta = radiusMeters / 111320;
  final cosLat = math.cos(latitude * math.pi / 180).abs().clamp(0.2, 1.0);
  final lonDelta = radiusMeters / (111320 * cosLat);

  final query = await _users
      .where('isVisible', isEqualTo: true)
      .where('latitude', isGreaterThanOrEqualTo: latitude - latDelta)
      .where('latitude', isLessThanOrEqualTo: latitude + latDelta)
      .limit(limit * 3)
      .get();

  final results = <NearbyUser>[];

  for (final doc in query.docs) {
    if (doc.id == currentUid) continue;
    if (doc.id.startsWith('demo_')) continue;

    final user = UserModel.fromMap(doc.data(), uid: doc.id);
    if (!user.hasLocation) continue;
    if (user.longitude! < longitude - lonDelta ||
        user.longitude! > longitude + lonDelta) {
      continue;
    }

    final meters = DistanceUtils.metersBetween(
      latitude,
      longitude,
      user.latitude!,
      user.longitude!,
    );

    if (meters <= radiusMeters) {
      results.add(NearbyUser(user: user, distanceMeters: meters));
    }
  }

  results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  if (results.length > limit) return results.sublist(0, limit);
  return results;
}
