import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/utils/location_privacy.dart';

// Re-export tipos de privacidad para no romper imports existentes.
export '../core/utils/location_privacy.dart'
    show ApproxLocation, LocationPrivacy;

// Geolocator SOLO se carga bajo demanda (fuera de DEMO).
import 'geo_locator_bridge.dart' deferred as geo;

enum LocationPermissionStatus {
  unknown,
  serviceDisabled,
  denied,
  permanentlyDenied,
  granted,
}

/// Servicio de ubicación con privacidad-first.
///
/// **DEMO_MODE:** cero plugins nativos, respuesta síncrona (Santiago fuzzed).
/// **Producción:** carga [geo_locator_bridge] de forma diferida + timeouts duros.
class LocationService {
  bool _geoLoaded = false;

  static double approximateCoordinate(double value) =>
      LocationPrivacy.approximateCoordinate(value);

  static ApproxLocation fuzz({
    required double latitude,
    required double longitude,
    double accuracyMeters = 150,
    DateTime? timestamp,
  }) =>
      LocationPrivacy.fuzz(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        timestamp: timestamp,
      );

  static ApproxLocation santiagoCenterApprox() =>
      LocationPrivacy.santiagoCenterApprox();

  static String formatApproxDistance(double meters) =>
      LocationPrivacy.formatApproxDistance(meters);

  Future<void> _ensureGeo() async {
    if (AppConfig.demoMode) {
      throw StateError('Geolocator no debe cargarse en DEMO_MODE');
    }
    if (_geoLoaded) return;
    if (kDebugMode) {
      debugPrint('📍 loading geo_locator_bridge (deferred)…');
    }
    await geo.loadLibrary().timeout(const Duration(seconds: 5));
    _geoLoaded = true;
  }

  Future<LocationPermissionStatus> checkPermissionStatus() async {
    if (AppConfig.demoMode) {
      return LocationPermissionStatus.granted;
    }
    try {
      await _ensureGeo();
      return await geo.geoCheckPermissionStatus();
    } catch (e) {
      debugPrint('checkPermissionStatus deferred error: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  Future<LocationPermissionStatus> requestPermission() async {
    if (AppConfig.demoMode) {
      return LocationPermissionStatus.granted;
    }
    try {
      await _ensureGeo();
      return await geo.geoRequestPermission();
    } catch (e) {
      debugPrint('requestPermission deferred error: $e');
      return LocationPermissionStatus.denied;
    }
  }

  Future<ApproxLocation> getApproxLocation({
    bool forceSantiago = true,
  }) async {
    if (AppConfig.demoMode) {
      return santiagoCenterApprox();
    }

    try {
      await _ensureGeo();
      return await geo
          .geoGetApproxLocation(forceSantiago: forceSantiago)
          .timeout(const Duration(seconds: 12));
    } on LocationServiceException {
      rethrow;
    } on TimeoutException {
      throw LocationServiceException(
        kIsWeb
            ? 'La ubicación tardó demasiado en el navegador.'
            : 'La ubicación tardó demasiado. Inténtalo de nuevo.',
        status: LocationPermissionStatus.granted,
      );
    } catch (e) {
      if (e is LocationServiceException) rethrow;
      debugPrint('getApproxLocation error: $e');
      throw LocationServiceException(
        'No pudimos obtener tu ubicación.',
        status: LocationPermissionStatus.unknown,
      );
    }
  }

  double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return LocationPrivacy.haversineMeters(lat1, lon1, lat2, lon2);
  }

  Future<void> openAppSettings() async {
    if (AppConfig.demoMode) return;
    try {
      await _ensureGeo();
      await geo.geoOpenAppSettings();
    } catch (e) {
      debugPrint('openAppSettings error: $e');
    }
  }

  Future<void> openLocationSettings() async {
    if (AppConfig.demoMode) return;
    try {
      await _ensureGeo();
      await geo.geoOpenLocationSettings();
    } catch (e) {
      debugPrint('openLocationSettings error: $e');
    }
  }

  Future<bool> isServiceEnabled() async {
    if (AppConfig.demoMode) return true;
    try {
      await _ensureGeo();
      return await geo.geoIsServiceEnabled();
    } catch (_) {
      return false;
    }
  }
}

class LocationServiceException implements Exception {
  LocationServiceException(this.message, {this.status});

  final String message;
  final LocationPermissionStatus? status;

  bool get isPermanentlyDenied =>
      status == LocationPermissionStatus.permanentlyDenied;

  bool get isDenied =>
      status == LocationPermissionStatus.denied ||
      status == LocationPermissionStatus.permanentlyDenied;

  bool get isServiceDisabled =>
      status == LocationPermissionStatus.serviceDisabled;

  @override
  String toString() => message;
}
