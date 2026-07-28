import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/santiago_bounds.dart';
import 'location_service.dart';

/// API top-level para carga deferred (sin tipos deferred en el caller).
///
/// Se importa con: `import 'geo_locator_bridge.dart' deferred as geo;`

Future<LocationPermissionStatus> geoCheckPermissionStatus() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 3));
    if (!enabled) return LocationPermissionStatus.serviceDisabled;

    final permission = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 3));
    return _mapPermission(permission);
  } on TimeoutException {
    debugPrint('geoCheckPermissionStatus timeout');
    return LocationPermissionStatus.unknown;
  } catch (e) {
    debugPrint('geoCheckPermissionStatus error: $e');
    return LocationPermissionStatus.unknown;
  }
}

Future<LocationPermissionStatus> geoRequestPermission() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 3));
    if (!enabled) return LocationPermissionStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 3));
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission()
          .timeout(const Duration(seconds: 12));
    }
    return _mapPermission(permission);
  } on TimeoutException {
    debugPrint('geoRequestPermission timeout');
    return LocationPermissionStatus.denied;
  } catch (e) {
    debugPrint('geoRequestPermission error: $e');
    if (kIsWeb) return LocationPermissionStatus.denied;
    return LocationPermissionStatus.unknown;
  }
}

Future<ApproxLocation> geoGetApproxLocation({
  bool forceSantiago = true,
}) async {
  final status = await geoRequestPermission();
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

    try {
      position = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('getLastKnownPosition error: $e');
    }

    position ??= await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
    );

    final approx = LocationPrivacy.fuzz(
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
    throw LocationServiceException(
      kIsWeb
          ? 'La ubicación tardó demasiado en el navegador.'
          : 'La ubicación tardó demasiado. Inténtalo de nuevo.',
      status: LocationPermissionStatus.granted,
    );
  } catch (e) {
    debugPrint('geoGetApproxLocation error: $e');
    throw LocationServiceException(
      kIsWeb
          ? 'No pudimos obtener tu ubicación en el navegador.'
          : 'No pudimos obtener tu ubicación. Inténtalo de nuevo.',
      status: LocationPermissionStatus.granted,
    );
  }
}

Future<void> geoOpenAppSettings() async {
  try {
    await Geolocator.openAppSettings().timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('openAppSettings error: $e');
  }
}

Future<void> geoOpenLocationSettings() async {
  try {
    await Geolocator.openLocationSettings()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('openLocationSettings error: $e');
  }
}

Future<bool> geoIsServiceEnabled() async {
  try {
    return await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    return false;
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
