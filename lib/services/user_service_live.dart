import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/privacy/buckets.dart';
import '../core/privacy/display_pin.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Implementación Firestore — solo se carga con deferred (no DEMO).
FirebaseFirestore get _db => FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> get _users =>
    _db.collection(AppConstants.usersCollection);

CollectionReference<Map<String, dynamic>> get _profiles =>
    _db.collection('profiles');

FirebaseFunctions get _fns =>
    FirebaseFunctions.instanceFor(region: AppConfig.region);

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Future<void> createUser(UserModel user) async {
  await _users.doc(user.uid).set({
    'email': user.email,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  await _profiles.doc(user.uid).set({
    'displayName': user.displayName,
    'bio': user.bio,
    'interests': user.interests,
    'photoUrl': user.photoUrl,
    'isVisible': user.isVisible,
    if (user.age != null) 'age': user.age,
  }, SetOptions(merge: true));
}

Future<UserModel?> getUser(String uid) async {
  try {
    final snap = await _profiles.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!, uid: snap.id);
  } catch (e) {
    debugPrint('getUser error: $e');
    return null;
  }
}

Stream<UserModel?> watchUser(String uid) {
  return _profiles.doc(uid).snapshots().map((snap) {
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
  await _profiles.doc(uid).set(data, SetOptions(merge: true));
}

Future<void> updateLocation({
  required String uid,
  required double latitude,
  required double longitude,
}) async {
  // La callable vuelve a difuminar y escribe solo locations/{uid}.
  await _fns.httpsCallable('updateLocation').call({
    'latitude': latitude,
    'longitude': longitude,
  });
}

Future<void> setOnlineStatus(String uid, bool isOnline) async {
  if (uid.isEmpty) return;
  // El cliente no escribe isOnline. El servidor calcula el bucket.
  await _fns.httpsCallable('touchActivity').call();
}

Future<List<NearbyUser>> getNearbyUsers({
  required String currentUid,
  required double latitude,
  required double longitude,
  double radiusMeters = SantiagoBounds.defaultSearchRadiusMeters,
  int limit = 50,
}) async {
  final response = await _fns.httpsCallable('getNearby').call({
    'radiusMeters': radiusMeters,
  });
  final root = _asMap(response.data);
  final rawPeople = root['people'];
  if (rawPeople is! List) return const [];

  final results = <NearbyUser>[];
  for (final item in rawPeople) {
    final row = _asMap(item);
    final uid = row['uid'] as String? ?? '';
    if (uid.isEmpty || uid == currentUid || uid.startsWith('demo_')) continue;
    final bucket = row['distanceBucket'] as String? ?? DistanceBuckets.km2;
    final activity = row['activityBucket'] as String? ?? ActivityBuckets.thisWeek;
    final profile = await getUser(uid);
    final user = profile ??
        UserModel(
          uid: uid,
          email: '',
          displayName: 'Persona',
          activityBucket: activity,
        );
    final pin = DisplayPin.onRing(
      originLat: latitude,
      originLon: longitude,
      uid: uid,
      bucket: bucket,
    );
    results.add(
      NearbyUser(
        user: user.copyWith(activityBucket: activity),
        distanceMeters: DistanceBuckets.displayMeters(bucket),
        distanceBucket: bucket,
        activityBucket: activity,
        displayLatitude: pin.latitude,
        displayLongitude: pin.longitude,
      ),
    );
    if (results.length >= limit) break;
  }
  return results;
}
