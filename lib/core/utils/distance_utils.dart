import 'dart:math' as math;

/// Utilidades de distancia (Haversine) en metros/km.
abstract final class DistanceUtils {
  static const double _earthRadiusMeters = 6371000;

  /// Distancia en metros entre dos coordenadas.
  static double metersBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Texto amigable en español chileno: "120 m", "1,2 km", "cerca".
  static String formatDistance(double meters) {
    if (meters < 50) return 'cerquita';
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    if (km < 10) {
      return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '${km.round()} km';
  }

  /// Etiqueta corta para chips: "< 500 m", "1 km", etc.
  static String formatDistanceShort(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    if (km < 10) {
      return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '${km.round()} km';
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
