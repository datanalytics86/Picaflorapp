import '../models/user_model.dart';
import '../services/user_service.dart';

/// Datos de ejemplo para Nearby cuando Firestore está vacío o falla.
/// Las distancias son fijas y se sienten naturales en Santiago.
abstract final class DemoNearby {
  static List<NearbyUser> people({
    required double originLat,
    required double originLon,
  }) {
    final now = DateTime.now();
    final samples = <UserModel>[
      UserModel(
        uid: 'demo_camila',
        email: '',
        displayName: 'Camila R.',
        bio: 'Café y museos por Providencia',
        interests: const ['café', 'arte', 'running'],
        latitude: originLat + 0.002,
        longitude: originLon + 0.001,
        isOnline: true,
        lastSeen: now,
      ),
      UserModel(
        uid: 'demo_matias',
        email: '',
        displayName: 'Matías V.',
        bio: 'Diseño y música en vivo',
        interests: const ['diseño', 'música'],
        latitude: originLat - 0.003,
        longitude: originLon + 0.002,
        isOnline: true,
        lastSeen: now.subtract(const Duration(minutes: 4)),
      ),
      UserModel(
        uid: 'demo_sofia',
        email: '',
        displayName: 'Sofía L.',
        bio: 'Arquitecta · Ñuñoa forever',
        interests: const ['arquitectura', 'foto'],
        latitude: originLat + 0.004,
        longitude: originLon - 0.002,
        isOnline: false,
        lastSeen: now.subtract(const Duration(hours: 2)),
      ),
      UserModel(
        uid: 'demo_diego',
        email: '',
        displayName: 'Diego P.',
        bio: 'Emprendedor y trekking de finde',
        interests: const ['startups', 'cerro'],
        latitude: originLat - 0.0015,
        longitude: originLon - 0.003,
        isOnline: true,
        lastSeen: now,
      ),
      UserModel(
        uid: 'demo_vale',
        email: '',
        displayName: 'Valentina M.',
        bio: 'Books & brunch en Lastarria',
        interests: const ['libros', 'brunch'],
        latitude: originLat + 0.006,
        longitude: originLon + 0.0015,
        isOnline: false,
        lastSeen: now.subtract(const Duration(days: 1)),
      ),
      UserModel(
        uid: 'demo_nico',
        email: '',
        displayName: 'Nicolás A.',
        bio: 'Dev · bike · buen asado',
        interests: const ['tech', 'bici'],
        latitude: originLat - 0.005,
        longitude: originLon + 0.004,
        isOnline: true,
        lastSeen: now.subtract(const Duration(minutes: 12)),
      ),
    ];

    // Distancias “decorativas” estables (no GPS real de demos).
    const distances = [120.0, 340.0, 580.0, 920.0, 1400.0, 2100.0];

    return [
      for (var i = 0; i < samples.length; i++)
        NearbyUser(user: samples[i], distanceMeters: distances[i]),
    ];
  }
}
