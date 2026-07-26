import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';

/// Ubicación **aproximada** (nunca coordenadas exactas).
///
/// Las coords se redondean a una grilla de ~150 m para privacidad.
@immutable
class ApproxLocation {
  const ApproxLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
  });

  /// Latitud aproximada (fuzzed).
  final double latitude;

  /// Longitud aproximada (fuzzed).
  final double longitude;

  /// Precisión reportada del GPS (informativa).
  final double accuracyMeters;

  final DateTime timestamp;

  bool get isInSantiago => SantiagoBounds.contains(latitude, longitude);

  @override
  String toString() =>
      'ApproxLocation($latitude, $longitude ±${accuracyMeters.round()}m)';
}

enum LocationPermissionStatus {
  /// Aún no se ha pedido.
  unknown,

  /// Servicio de ubicación del sistema apagado.
  serviceDisabled,

  /// Usuario denegó (se puede volver a pedir).
  denied,

  /// Denegado para siempre → hay que ir a Ajustes.
  permanentlyDenied,

  /// Listo para usar.
  granted,
}

/// Servicio de ubicación con privacidad-first y validación Santiago.
///
/// En [AppConfig.demoMode] **nunca** toca Geolocator (evita freezes en web).
class LocationService {
  /// Tamaño de grilla en grados ≈ 150 m (lat).
  /// 0.001° lat ≈ 111 m → 0.0014° ≈ 155 m.
  static const double _gridDegrees = 0.0014;

  /// Timeout de GPS en producción (web cuelga si es muy largo).
  static const Duration _currentPositionTimeout = Duration(seconds: 8);

  /// Redondea una coordenada a la grilla de privacidad.
  static double approximateCoordinate(double value) {
    return (value / _gridDegrees).round() * _gridDegrees;
  }

  /// Convierte lat/lng exactos en ubicación aproximada.
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

  /// Centro de Santiago ya fuzzed (modo demo / fallback).
  static ApproxLocation santiagoCenterApprox() {
    return fuzz(
      latitude: SantiagoBounds.centerLatitude,
      longitude: SantiagoBounds.centerLongitude,
      accuracyMeters: 150,
    );
  }

  /// Estado actual de permisos (sin pedirlos).
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    if (AppConfig.demoMode) {
      return LocationPermissionStatus.granted;
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationPermissionStatus.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('checkPermissionStatus error: $e');
      // En web el plugin a veces falla sin prompt.
      if (kIsWeb) return LocationPermissionStatus.unknown;
      return LocationPermissionStatus.unknown;
    }
  }

  /// Pide permiso si hace falta. No lanza: devuelve el estado final.
  Future<LocationPermissionStatus> requestPermission() async {
    if (AppConfig.demoMode) {
      return LocationPermissionStatus.granted;
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationPermissionStatus.serviceDisabled;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return _mapPermission(permission);
    } catch (e) {
      debugPrint('requestPermission error: $e');
      if (kIsWeb) {
        // El browser puede bloquear el prompt; el caller muestra mensaje.
        return LocationPermissionStatus.denied;
      }
      return LocationPermissionStatus.unknown;
    }
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  /// Obtiene ubicación **aproximada** actual.
  ///
  /// - Demo: centro de Santiago, sin GPS.
  /// - Prod: lastKnown → getCurrentPosition (8s).
  /// - Nunca devuelve coords crudas: siempre pasan por [fuzz].
  Future<ApproxLocation> getApproxLocation({
    bool forceSantiago = true,
  }) async {
    if (AppConfig.demoMode) {
      return santiagoCenterApprox();
    }

    final status = await requestPermission();
    if (status == LocationPermissionStatus.serviceDisabled) {
      throw LocationServiceException(
        'Activa la ubicación del teléfono para ver gente cerca.',
        status: status,
      );
    }
    if (status == LocationPermissionStatus.denied) {
      throw LocationServiceException(
        kIsWeb
            ? 'Permite la ubicación en el navegador para ver gente cerca.'
            : 'Necesitamos tu ubicación (aproximada) para mostrarte gente cerca.',
        status: status,
      );
    }
    if (status == LocationPermissionStatus.permanentlyDenied) {
      throw LocationServiceException(
        'La ubicación está bloqueada. Ábrela en Ajustes.',
        status: status,
      );
    }
    if (status != LocationPermissionStatus.granted) {
      throw LocationServiceException(
        'No pudimos acceder a la ubicación.',
        status: status,
      );
    }

    try {
      Position? position;

      // 1) Last known: instantáneo cuando existe (nativo / algo de web).
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('getLastKnownPosition error: $e');
      }

      // 2) Current con timeout corto (evita freeze en web).
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: _currentPositionTimeout,
      );

      final approx = fuzz(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
      );

      if (forceSantiago && !approx.isInSantiago) {
        final rawIn = SantiagoBounds.contains(
          position.latitude,
          position.longitude,
        );
        if (!rawIn) {
          throw LocationServiceException(
            SantiagoBounds.outOfBoundsMessage,
            status: LocationPermissionStatus.granted,
          );
        }
      }

      return approx;
    } on LocationServiceException {
      rethrow;
    } on TimeoutException {
      debugPrint('getApproxLocation timeout');
      throw LocationServiceException(
        kIsWeb
            ? 'La ubicación tardó demasiado en el navegador. Intenta de nuevo o revisa los permisos del sitio.'
            : 'La ubicación tardó demasiado. Inténtalo de nuevo.',
        status: LocationPermissionStatus.granted,
      );
    } catch (e) {
      debugPrint('getApproxLocation error: $e');
      throw LocationServiceException(
        kIsWeb
            ? 'No pudimos obtener tu ubicación en el navegador.'
            : 'No pudimos obtener tu ubicación. Inténtalo de nuevo.',
        status: LocationPermissionStatus.granted,
      );
    }
  }

  /// Distancia en metros entre dos puntos (ya deberían ser approx).
  double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Etiqueta de distancia aproximada en español chileno.
  static String formatApproxDistance(double meters) {
    if (meters < 80) return 'muy cerca';
    if (meters < 200) return 'cerca';
    if (meters < 1000) {
      // Redondeo a 50 m para no parecer exacto.
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

  Future<void> openAppSettings() async {
    if (AppConfig.demoMode) return;
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('openAppSettings error: $e');
    }
  }

  Future<void> openLocationSettings() async {
    if (AppConfig.demoMode) return;
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('openLocationSettings error: $e');
    }
  }

  Future<bool> isServiceEnabled() async {
    if (AppConfig.demoMode) return true;
    try {
      return await Geolocator.isLocationServiceEnabled();
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
