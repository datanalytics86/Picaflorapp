/// Buckets de distancia y actividad. No son coordenadas.
abstract final class DistanceBuckets {
  static const veryClose = 'very_close';
  static const m300 = 'm300';
  static const m800 = 'm800';
  static const km2 = 'km2';
  static const km5 = 'km5';
  static const km10 = 'km10';

  static String fromMeters(double meters) {
    if (meters < 150) return veryClose;
    if (meters < 450) return m300;
    if (meters < 1200) return m800;
    if (meters < 2500) return km2;
    if (meters < 6000) return km5;
    return km10;
  }

  static String label(String bucket) {
    return switch (bucket) {
      veryClose => 'muy cerca',
      m300 => '~300 m',
      m800 => '~800 m',
      km2 => '~2 km',
      km5 => '~5 km',
      km10 => '~10 km',
      _ => 'cerca',
    };
  }

  /// Radio de dibujo del pin (no es la posición real).
  static double displayMeters(String bucket) {
    return switch (bucket) {
      veryClose => 90,
      m300 => 300,
      m800 => 800,
      km2 => 1800,
      km5 => 4500,
      km10 => 8000,
      _ => 1800,
    };
  }
}

abstract final class ActivityBuckets {
  static const now = 'ahora';
  static const today = 'hoy';
  static const thisWeek = 'esta_semana';
  static const inactive = 'inactivo';

  static String fromLastActive(DateTime? lastActive, DateTime now) {
    if (lastActive == null) return inactive;
    final delta = now.difference(lastActive);
    if (delta.isNegative) return ActivityBuckets.now;
    if (delta.inMinutes <= 15) return ActivityBuckets.now;
    if (delta.inHours < 24) return today;
    if (delta.inDays <= 7) return thisWeek;
    return inactive;
  }

  static String label(String bucket) {
    return switch (bucket) {
      now => 'activa ahora',
      today => 'activa hoy',
      thisWeek => 'activa esta semana',
      _ => 'sin actividad reciente',
    };
  }
}
