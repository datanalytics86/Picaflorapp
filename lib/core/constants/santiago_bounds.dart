/// Límites geográficos aproximados del Gran Santiago.
/// Se usan para validar que el usuario esté dentro del área de cobertura
/// de Picaflor y para acotar búsquedas de gente cercana.
abstract final class SantiagoBounds {
  // Bounding box del Gran Santiago (aprox.)
  static const double minLatitude = -33.65;
  static const double maxLatitude = -33.25;
  static const double minLongitude = -70.85;
  static const double maxLongitude = -70.45;

  /// Centro de referencia (Plaza de Armas / centro histórico).
  static const double centerLatitude = -33.4489;
  static const double centerLongitude = -70.6693;

  /// Radio máximo de búsqueda de personas cercanas (metros).
  static const double defaultSearchRadiusMeters = 2500;

  /// Radio mínimo permitido en el slider de distancia.
  static const double minSearchRadiusMeters = 200;

  /// Radio máximo permitido en el slider de distancia.
  static const double maxSearchRadiusMeters = 10000;

  /// Precisión mínima aceptable del GPS (metros).
  static const double maxLocationAccuracyMeters = 100;

  /// ¿La coordenada cae dentro del bounding box de Santiago?
  static bool contains(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }

  /// Mensaje amigable cuando el usuario está fuera de cobertura.
  static const String outOfBoundsMessage =
      'Por ahora Picaflor solo funciona en el Gran Santiago. '
      'Pronto llegamos a más ciudades 🐦';
}
