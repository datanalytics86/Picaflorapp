import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';
import '../core/utils/location_privacy.dart';
import '../data/demo_nearby.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'user_provider.dart';

/// Resultado de Nearby: gente real o demo de respaldo.
class NearbyResult {
  const NearbyResult({
    required this.people,
    this.isDemo = false,
    this.error,
  });

  final List<NearbyUser> people;
  final bool isDemo;
  final String? error;

  bool get isEmpty => people.isEmpty;
}

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
    final uid = ref.watch(authServiceProvider).currentUid ?? 'local';

    final people = DemoNearby.people(originLat: lat, originLon: lon)
        .where((p) => p.user.uid != uid)
        .where((p) => p.distanceMeters <= radius)
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
  final uid = ref.watch(authServiceProvider).currentUid ?? 'local';
  final hasLocation = ref.watch(
    locationControllerProvider.select((s) => s.hasLocation),
  );

  if (!hasLocation) {
    return NearbyResult(
      people: DemoNearby.people(originLat: lat, originLon: lon)
          .where((p) => p.distanceMeters <= radius)
          .toList(growable: false),
      isDemo: true,
    );
  }

  try {
    final people = await ref
        .read(userServiceProvider)
        .getNearbyUsers(
          currentUid: uid,
          latitude: lat,
          longitude: lon,
          radiusMeters: radius,
        )
        .timeout(const Duration(seconds: 8));

    if (people.isEmpty) {
      final demo = DemoNearby.people(originLat: lat, originLon: lon)
          .where((p) => p.distanceMeters <= radius)
          .toList(growable: false);
      return NearbyResult(people: demo, isDemo: true);
    }

    return NearbyResult(people: people, isDemo: false);
  } catch (_) {
    final demo = DemoNearby.people(originLat: lat, originLon: lon)
        .where((p) => p.distanceMeters <= radius)
        .toList(growable: false);
    return NearbyResult(
      people: demo,
      isDemo: true,
      error: 'Mostrando ejemplos. Revisa tu conexión.',
    );
  }
});

String nearbyDistanceLabel(double meters) =>
    LocationPrivacy.formatApproxDistance(meters);
