import '../core/utils/location_privacy.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Datos de ejemplo para Nearby cuando Firestore está vacío o falla.
///
/// **Privacidad:** todas las coordenadas pasan por [LocationService.fuzz]
/// (~150 m). Nunca se exponen posiciones exactas.
abstract final class DemoNearby {
  static List<NearbyUser> people({
    required double originLat,
    required double originLon,
  }) {
    final now = DateTime.now();

    // Offsets decorativos respecto al origen; se fuzzean al construir.
    final raw = <({
      String uid,
      String name,
      String bio,
      List<String> interests,
      double dLat,
      double dLon,
      bool online,
      Duration lastSeenAgo,
    })>[
      (
        uid: 'demo_camila',
        name: 'Camila R.',
        bio: 'Café y museos por Providencia',
        interests: const ['café', 'arte', 'running'],
        dLat: 0.002,
        dLon: 0.001,
        online: true,
        lastSeenAgo: Duration.zero,
      ),
      (
        uid: 'demo_matias',
        name: 'Matías V.',
        bio: 'Diseño y música en vivo',
        interests: const ['diseño', 'música'],
        dLat: -0.003,
        dLon: 0.002,
        online: true,
        lastSeenAgo: const Duration(minutes: 4),
      ),
      (
        uid: 'demo_sofia',
        name: 'Sofía L.',
        bio: 'Arquitecta · Ñuñoa forever',
        interests: const ['arquitectura', 'foto'],
        dLat: 0.004,
        dLon: -0.002,
        online: false,
        lastSeenAgo: const Duration(hours: 2),
      ),
      (
        uid: 'demo_diego',
        name: 'Diego P.',
        bio: 'Emprendedor y trekking de finde',
        interests: const ['startups', 'cerro'],
        dLat: -0.0015,
        dLon: -0.003,
        online: true,
        lastSeenAgo: Duration.zero,
      ),
      (
        uid: 'demo_vale',
        name: 'Valentina M.',
        bio: 'Books & brunch en Lastarria',
        interests: const ['libros', 'brunch'],
        dLat: 0.006,
        dLon: 0.0015,
        online: false,
        lastSeenAgo: const Duration(days: 1),
      ),
      (
        uid: 'demo_nico',
        name: 'Nicolás A.',
        bio: 'Dev · bike · buen asado',
        interests: const ['tech', 'bici'],
        dLat: -0.005,
        dLon: 0.004,
        online: true,
        lastSeenAgo: const Duration(minutes: 12),
      ),
    ];

    // Distancias “decorativas” estables (no GPS real de demos).
    const distances = [120.0, 340.0, 580.0, 920.0, 1400.0, 2100.0];

    return [
      for (var i = 0; i < raw.length; i++)
        NearbyUser(
          user: _fuzzedUser(
            uid: raw[i].uid,
            displayName: raw[i].name,
            bio: raw[i].bio,
            interests: raw[i].interests,
            originLat: originLat,
            originLon: originLon,
            dLat: raw[i].dLat,
            dLon: raw[i].dLon,
            isOnline: raw[i].online,
            lastSeen: now.subtract(raw[i].lastSeenAgo),
          ),
          distanceMeters: distances[i],
        ),
    ];
  }

  static UserModel _fuzzedUser({
    required String uid,
    required String displayName,
    required String bio,
    required List<String> interests,
    required double originLat,
    required double originLon,
    required double dLat,
    required double dLon,
    required bool isOnline,
    required DateTime lastSeen,
  }) {
    final approx = LocationPrivacy.fuzz(
      latitude: originLat + dLat,
      longitude: originLon + dLon,
      accuracyMeters: 150,
    );
    return UserModel(
      uid: uid,
      email: '',
      displayName: displayName,
      bio: bio,
      interests: interests,
      latitude: approx.latitude,
      longitude: approx.longitude,
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }
}
