import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/santiago_bounds.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';
import 'theme_provider.dart';
import 'user_provider.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// Estado de ubicación (siempre aproximada).
class LocationState {
  const LocationState({
    this.location,
    this.permission = LocationPermissionStatus.unknown,
    this.isLoading = false,
    this.error,
    this.radiusMeters = SantiagoBounds.defaultSearchRadiusMeters,
  });

  final ApproxLocation? location;
  final LocationPermissionStatus permission;
  final bool isLoading;
  final String? error;
  final double radiusMeters;

  bool get hasLocation => location != null;

  bool get needsPermission =>
      permission == LocationPermissionStatus.denied ||
      permission == LocationPermissionStatus.permanentlyDenied ||
      permission == LocationPermissionStatus.unknown;

  bool get isPermanentlyDenied =>
      permission == LocationPermissionStatus.permanentlyDenied;

  bool get isServiceDisabled =>
      permission == LocationPermissionStatus.serviceDisabled;

  LocationState copyWith({
    ApproxLocation? location,
    LocationPermissionStatus? permission,
    bool? isLoading,
    String? error,
    double? radiusMeters,
    bool clearError = false,
    bool clearLocation = false,
  }) {
    return LocationState(
      location: clearLocation ? null : (location ?? this.location),
      permission: permission ?? this.permission,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}

class LocationController extends StateNotifier<LocationState> {
  LocationController(this._location, this._prefs, this._ref)
      : super(LocationState(
          radiusMeters: _prefs.getDouble(AppConstants.keySearchRadius) ??
              SantiagoBounds.defaultSearchRadiusMeters,
        ));

  final LocationService _location;
  final SharedPreferences _prefs;
  final Ref _ref;

  /// Solo revisa permisos (sin GPS).
  Future<void> checkPermission() async {
    final status = await _location.checkPermissionStatus();
    state = state.copyWith(permission: status);
  }

  /// Pide permiso + obtiene ubicación aproximada + opcionalmente sincroniza.
  Future<bool> refresh({bool updateFirestore = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // En demo, si no hay GPS usamos el centro de Santiago.
    if (AppConfig.demoMode) {
      try {
        final status = await _location.requestPermission();
        if (status == LocationPermissionStatus.granted) {
          final approx = await _location.getApproxLocation();
          state = state.copyWith(
            location: approx,
            isLoading: false,
            permission: LocationPermissionStatus.granted,
            clearError: true,
          );
        } else {
          _useSantiagoFallback();
        }
      } catch (_) {
        _useSantiagoFallback();
      }

      if (updateFirestore) {
        final uid = _ref.read(authServiceProvider).currentUid;
        final loc = state.location;
        if (uid != null && loc != null) {
          await _ref.read(userServiceProvider).updateLocation(
                uid: uid,
                latitude: loc.latitude,
                longitude: loc.longitude,
              );
        }
      }
      return true;
    }

    try {
      final status = await _location.requestPermission();
      state = state.copyWith(permission: status);

      if (status != LocationPermissionStatus.granted) {
        final msg = switch (status) {
          LocationPermissionStatus.serviceDisabled =>
            'Activa la ubicación del teléfono para ver gente cerca.',
          LocationPermissionStatus.permanentlyDenied =>
            'La ubicación está bloqueada. Ábrela en Ajustes.',
          LocationPermissionStatus.denied =>
            'Necesitamos tu ubicación aproximada para mostrarte gente cerca.',
          _ => 'No pudimos acceder a la ubicación.',
        };
        state = state.copyWith(isLoading: false, error: msg);
        return false;
      }

      final approx = await _location.getApproxLocation();
      state = state.copyWith(
        location: approx,
        isLoading: false,
        permission: LocationPermissionStatus.granted,
      );

      if (updateFirestore) {
        final uid = _ref.read(authServiceProvider).currentUid;
        if (uid != null) {
          await _ref.read(userServiceProvider).updateLocation(
                uid: uid,
                latitude: approx.latitude,
                longitude: approx.longitude,
              );
        }
      }
      return true;
    } on LocationServiceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        permission: e.status ?? state.permission,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos obtener tu ubicación.',
      );
      return false;
    }
  }

  void _useSantiagoFallback() {
    final approx = LocationService.fuzz(
      latitude: SantiagoBounds.centerLatitude,
      longitude: SantiagoBounds.centerLongitude,
    );
    state = state.copyWith(
      location: approx,
      isLoading: false,
      permission: LocationPermissionStatus.granted,
      clearError: true,
    );
  }

  Future<void> openSettings() async {
    if (state.isServiceDisabled) {
      await _location.openLocationSettings();
    } else {
      await _location.openAppSettings();
    }
  }

  Future<void> setRadius(double meters) async {
    final clamped = meters.clamp(
      SantiagoBounds.minSearchRadiusMeters,
      SantiagoBounds.maxSearchRadiusMeters,
    );
    state = state.copyWith(radiusMeters: clamped.toDouble());
    await _prefs.setDouble(AppConstants.keySearchRadius, clamped.toDouble());
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(
    ref.watch(locationServiceProvider),
    ref.watch(sharedPreferencesProvider),
    ref,
  );
});
