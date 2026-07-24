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
final nearbyUsersProvider =
    FutureProvider.autoDispose<NearbyResult>((ref) async {
  final location = ref.watch(locationControllerProvider);
  final uid = ref.watch(authServiceProvider).currentUid ?? 'local';

  final lat = location.location?.latitude ?? SantiagoBounds.centerLatitude;
  final lon = location.location?.longitude ?? SantiagoBounds.centerLongitude;
  final radius = location.radiusMeters;

  // Modo demo: siempre personas de ejemplo (filtradas por radio).
  if (AppConfig.demoMode) {
    final people = await ref.watch(userServiceProvider).getNearbyUsers(
          currentUid: uid,
          latitude: lat,
          longitude: lon,
          radiusMeters: radius,
        );
    return NearbyResult(people: people, isDemo: true);
  }

  // Sin ubicación real aún: demos del centro de Stgo.
  if (!location.hasLocation) {
    return NearbyResult(
      people: DemoNearby.people(originLat: lat, originLon: lon)
          .where((p) => p.distanceMeters <= radius)
          .toList(),
      isDemo: true,
    );
  }

  try {
    final people = await ref.watch(userServiceProvider).getNearbyUsers(
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
  } catch (e) {
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
