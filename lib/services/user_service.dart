import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/utils/location_privacy.dart';
import '../data/demo_nearby.dart';
import '../data/demo_store.dart';
import '../models/user_model.dart';

// Firestore SOLO fuera de DEMO.
import 'user_service_live.dart' deferred as live;

/// CRUD y consultas de usuarios.
///
/// DEMO: [DemoStore] síncrono/local — **cero** cloud_firestore en el import graph.
class UserService {
  UserService({bool? demoMode}) : _isDemo = demoMode ?? AppConfig.demoMode;

  final bool _isDemo;
  bool _liveLoaded = false;

  Future<void> _ensureLive() async {
    if (_isDemo) throw StateError('User live no se carga en DEMO');
    if (_liveLoaded) return;
    await live.loadLibrary().timeout(const Duration(seconds: 6));
    _liveLoaded = true;
  }

  Future<void> createUser(UserModel user) async {
    if (_isDemo) {
      await DemoStore.instance.createUser(user);
      return;
    }
    await _ensureLive();
    await live.createUser(user);
  }

  Future<UserModel?> getUser(String uid) async {
    if (_isDemo) return DemoStore.instance.getUser(uid);
    await _ensureLive();
    return live.getUser(uid);
  }

  Stream<UserModel?> watchUser(String uid) {
    if (_isDemo) return DemoStore.instance.watchUser(uid);
    // Lazy stream: carga live en el primer listen.
    return Stream.multi((listener) async {
      try {
        await _ensureLive();
        final sub = live.watchUser(uid).listen(
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
    await _ensureLive();
    await live.updateUser(uid, data);
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
    await _ensureLive();
    await live.updateProfile(
      uid: uid,
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
      interests: interests,
      isVisible: isVisible,
    );
  }

  Future<void> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    final approx = LocationPrivacy.fuzz(
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
    await _ensureLive();
    await live.updateLocation(
      uid: uid,
      latitude: approx.latitude,
      longitude: approx.longitude,
    );
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    if (_isDemo) {
      await DemoStore.instance.setOnlineStatus(uid, isOnline);
      return;
    }
    await _ensureLive();
    await live.setOnlineStatus(uid, isOnline);
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
      return DemoNearby.people(originLat: latitude, originLon: longitude)
          .where((p) => p.user.uid != currentUid)
          .where((p) => p.distanceMeters <= radiusMeters)
          .take(limit)
          .toList(growable: false);
    }
    await _ensureLive();
    return live.getNearbyUsers(
      currentUid: currentUid,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      limit: limit,
    );
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
      LocationPrivacy.formatApproxDistance(distanceMeters);
}
