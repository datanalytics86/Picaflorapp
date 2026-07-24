import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/utils/distance_utils.dart';
import '../data/demo_nearby.dart';
import '../data/demo_store.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';

/// CRUD y consultas de usuarios.
///
/// En modo demo usa [DemoStore]; en producción, Firestore.
class UserService {
  UserService({
    FirebaseFirestore? firestore,
    bool? demoMode,
  }) : _isDemo = demoMode ?? AppConfig.demoMode {
    if (!_isDemo) {
      _db = firestore ?? FirebaseFirestore.instance;
    }
  }

  final bool _isDemo;
  FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db!.collection(AppConstants.usersCollection);

  Future<void> createUser(UserModel user) async {
    if (_isDemo) {
      await DemoStore.instance.createUser(user);
      return;
    }
    await _users.doc(user.uid).set(user.toCreateMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    if (_isDemo) return DemoStore.instance.getUser(uid);
    try {
      final snap = await _users.doc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromFirestore(snap);
    } catch (e) {
      debugPrint('getUser error: $e');
      return null;
    }
  }

  Stream<UserModel?> watchUser(String uid) {
    if (_isDemo) return DemoStore.instance.watchUser(uid);
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromFirestore(snap);
    }).handleError((e) {
      debugPrint('watchUser error: $e');
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (_isDemo) {
      await DemoStore.instance.updateProfile(
        uid: uid,
        displayName: data['displayName'] as String?,
        bio: data['bio'] as String?,
        photoUrl: data['photoUrl'] as String?,
        interests: (data['interests'] as List?)?.cast<String>(),
        isVisible: data['isVisible'] as bool?,
      );
      return;
    }
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
    if (_isDemo) {
      await DemoStore.instance.updateProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
        photoUrl: photoUrl,
        interests: interests,
        isVisible: isVisible,
      );
      return;
    }

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
    final approx = LocationService.fuzz(
      latitude: latitude,
      longitude: longitude,
    );

    if (_isDemo) {
      await DemoStore.instance.updateLocation(
        uid: uid,
        latitude: approx.latitude,
        longitude: approx.longitude,
      );
      return;
    }

    await _users.doc(uid).set({
      'latitude': approx.latitude,
      'longitude': approx.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    if (_isDemo) {
      await DemoStore.instance.setOnlineStatus(uid, isOnline);
      return;
    }
    await _users.doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setVisibility(String uid, bool isVisible) async {
    await updateProfile(uid: uid, isVisible: isVisible);
  }

  Future<List<NearbyUser>> getNearbyUsers({
    required String currentUid,
    required double latitude,
    required double longitude,
    double radiusMeters = SantiagoBounds.defaultSearchRadiusMeters,
    int limit = 50,
  }) async {
    if (_isDemo) {
      final demo = DemoNearby.people(
        originLat: latitude,
        originLon: longitude,
      )
          .where((p) => p.user.uid != currentUid)
          .where((p) => p.distanceMeters <= radiusMeters)
          .take(limit)
          .toList();
      return demo;
    }

    try {
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

        final user = UserModel.fromFirestore(doc);
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
    } catch (e) {
      debugPrint('getNearbyUsers error: $e');
      rethrow;
    }
  }
}

class NearbyUser {
  const NearbyUser({
    required this.user,
    required this.distanceMeters,
  });

  final UserModel user;
  final double distanceMeters;

  String get distanceLabel =>
      LocationService.formatApproxDistance(distanceMeters);
}
