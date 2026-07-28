import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../constants/santiago_bounds.dart';

/// Ubicación **aproximada** (nunca coordenadas exactas).
///
/// Puro Dart — sin Geolocator ni plugins nativos (seguro en web/demo).
@immutable
class ApproxLocation {
  const ApproxLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;

  bool get isInSantiago => SantiagoBounds.contains(latitude, longitude);

  @override
  String toString() =>
      'ApproxLocation($latitude, $longitude ±${accuracyMeters.round()}m)';
}

/// Privacidad de ubicación: grilla ~150 m + distancias legibles.
///
/// Separado de plugins nativos para que el arranque DEMO/web
/// **nunca** cargue Geolocator.
abstract final class LocationPrivacy {
  /// 0.001° lat ≈ 111 m → 0.0014° ≈ 155 m.
  static const double gridDegrees = 0.0014;

  static double approximateCoordinate(double value) {
    return (value / gridDegrees).round() * gridDegrees;
  }

  static ApproxLocation fuzz({
    required double latitude,
    required double longitude,
    double accuracyMeters = 150,
    DateTime? timestamp,
  }) {
    return ApproxLocation(
      latitude: approximateCoordinate(latitude),
      longitude: approximateCoordinate(longitude),
      accuracyMeters: math.max(accuracyMeters, 100),
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  static ApproxLocation santiagoCenterApprox() {
    return fuzz(
      latitude: SantiagoBounds.centerLatitude,
      longitude: SantiagoBounds.centerLongitude,
      accuracyMeters: 150,
    );
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Etiqueta de distancia aproximada (español chileno).
  static String formatApproxDistance(double meters) {
    if (meters < 80) return 'muy cerca';
    if (meters < 200) return 'cerca';
    if (meters < 1000) {
      final rounded = (meters / 50).round() * 50;
      return '~$rounded m';
    }
    final km = meters / 1000;
    if (km < 10) {
      final rounded = (km * 10).round() / 10;
      return '~${rounded.toStringAsFixed(1).replaceAll('.', ',')} km';
    }
    return '~${km.round()} km';
  }
}
