import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/privacy/nearby_policy.dart';
import '../core/utils/location_privacy.dart';
import '../data/demo_nearby.dart';
import '../features/safety/safety_controller.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'user_provider.dart';

export '../core/privacy/nearby_policy.dart' show NearbyResult;

/// Personas cercanas.
///
/// En DEMO es **síncrono** (Provider) — no hay AsyncLoading eterno.
/// En producción usa FutureProvider con timeouts.
final nearbyUsersProvider = Provider.autoDispose<AsyncValue<NearbyResult>>((ref) {
  if (AppConfig.demoMode) {
    final lat = ref.watch(
      locationControllerProvider.select(
        (s) => s.location?.latitude ?? SantiagoBounds.centerLatitude,
      ),
    );
    final lon = ref.watch(
      locationControllerProvider.select(
        (s) => s.location?.longitude ?? SantiagoBounds.centerLongitude,
      ),
    );
    final radius = ref.watch(
      locationControllerProvider.select((s) => s.radiusMeters),
    );
    final uid = ref.watch(sessionProvider.select((s) => s?.uid)) ?? 'local';
    final blocked = ref.watch(safetyControllerProvider).blocked;

    final people = DemoNearby.people(originLat: lat, originLon: lon)
        .where((p) => p.user.uid != uid)
        .where((p) => p.distanceMeters <= radius)
        .where((p) => !blocked.contains(p.user.uid))
        .toList(growable: false);

    if (kDebugMode) {
      debugPrint('📍 nearby DEMO sync people=${people.length}');
    }
    return AsyncValue.data(
      NearbyResult(people: people, isDemo: true),
    );
  }

  // Producción: delega al FutureProvider con red.
  return ref.watch(_nearbyUsersRemoteProvider);
});

final _nearbyUsersRemoteProvider =
    FutureProvider.autoDispose<NearbyResult>((ref) async {
  final lat = ref.watch(
    locationControllerProvider.select(
      (s) => s.location?.latitude ?? SantiagoBounds.centerLatitude,
    ),
  );
  final lon = ref.watch(
    locationControllerProvider.select(
      (s) => s.location?.longitude ?? SantiagoBounds.centerLongitude,
    ),
  );
  final radius = ref.watch(
    locationControllerProvider.select((s) => s.radiusMeters),
  );
  final uid = ref.watch(sessionProvider.select((s) => s?.uid)) ?? 'local';
  final blocked = ref.watch(safetyControllerProvider).blocked;
  final hasLocation = ref.watch(
    locationControllerProvider.select((s) => s.hasLocation),
  );

  List<NearbyUser> remote = const [];
  var failed = false;
  if (hasLocation) {
    try {
      remote = await ref
          .read(userServiceProvider)
          .getNearbyUsers(
            currentUid: uid,
            latitude: lat,
            longitude: lon,
            radiusMeters: radius,
          )
          .timeout(const Duration(seconds: 8));
      remote = remote
          .where((p) => !blocked.contains(p.user.uid))
          .toList(growable: false);
    } catch (_) {
      failed = true;
    }
  }

  return NearbyPolicy.resolve(
    demoMode: false,
    hasLocation: hasLocation,
    failed: failed,
    remote: remote,
    demoPeople: const [],
  );
});

String nearbyDistanceLabel(double meters) =>
    LocationPrivacy.formatApproxDistance(meters);
