import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';
import '../data/demo_nearby.dart';
import '../services/location_service.dart';
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

/// Personas cercanas (Firestore o catálogo demo).
///
/// Solo reacciona a lat/lon/radius — no a flips de isLoading del GPS.
final nearbyUsersProvider =
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

  // Demo: 100% síncrono, sin red ni Geolocator.
  if (AppConfig.demoMode) {
    final people = DemoNearby.people(originLat: lat, originLon: lon)
        .where((p) => p.user.uid != uid)
        .where((p) => p.distanceMeters <= radius)
        .toList();
    return NearbyResult(people: people, isDemo: true);
  }

  // Sin ubicación real aún: demos del centro de Stgo.
  final hasLocation = ref.watch(
    locationControllerProvider.select((s) => s.hasLocation),
  );
  if (!hasLocation) {
    return NearbyResult(
      people: DemoNearby.people(originLat: lat, originLon: lon)
          .where((p) => p.distanceMeters <= radius)
          .toList(),
      isDemo: true,
    );
  }

  try {
    final people = await ref.read(userServiceProvider).getNearbyUsers(
          currentUid: uid,
          latitude: lat,
          longitude: lon,
          radiusMeters: radius,
        );

    if (people.isEmpty) {
      final demo = DemoNearby.people(originLat: lat, originLon: lon)
          .where((p) => p.distanceMeters <= radius)
          .toList();
      return NearbyResult(people: demo, isDemo: true);
    }

    return NearbyResult(people: people, isDemo: false);
  } catch (_) {
    final demo = DemoNearby.people(originLat: lat, originLon: lon)
        .where((p) => p.distanceMeters <= radius)
        .toList();
    return NearbyResult(
      people: demo,
      isDemo: true,
      error: 'Mostrando ejemplos. Revisa tu conexión.',
    );
  }
});

String nearbyDistanceLabel(double meters) =>
    LocationService.formatApproxDistance(meters);
