import 'dart:math' as math;

import 'buckets.dart';

/// Punto de mapa SOLO para dibujar. Sale del bucket, no de la coordenada real.
class DisplayPin {
  const DisplayPin(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static DisplayPin onRing({
    required double originLat,
    required double originLon,
    required String uid,
    required String bucket,
  }) {
    final meters = DistanceBuckets.displayMeters(bucket);
    var hash = 0;
    for (final c in uid.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final angle = (hash % 360) * math.pi / 180;
    final dLat = (meters * math.cos(angle)) / 111320;
    final cosLat = math.cos(originLat * math.pi / 180).abs().clamp(0.2, 1.0);
    final dLon = (meters * math.sin(angle)) / (111320 * cosLat);
    return DisplayPin(originLat + dLat, originLon + dLon);
  }
}
