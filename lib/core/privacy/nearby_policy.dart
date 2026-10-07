import '../../services/user_service.dart';

/// Decisión de qué mostrar en Cerca.
///
/// En producción nunca se rellenan huecos con personas de demo.
class NearbyResult {
  const NearbyResult({
    required this.people,
    this.isDemo = false,
    this.error,
  });

  final List<NearbyUser> people;
  final bool isDemo;
  final String? error;

  bool get isEmpty => people.isEmpty;
}

abstract final class NearbyPolicy {
  static const emptyLocationMessage =
      'Activa tu ubicación para ver gente cerca. Tu punto exacto no se comparte.';
  static const loadErrorMessage =
      'No pudimos cargar a la gente cerca. Revisa tu conexión y reintenta.';

  static NearbyResult resolve({
    required bool demoMode,
    required bool hasLocation,
    required bool failed,
    required List<NearbyUser> remote,
    required List<NearbyUser> demoPeople,
  }) {
    if (demoMode) {
      return NearbyResult(people: demoPeople, isDemo: true);
    }
    if (!hasLocation) {
      return const NearbyResult(
        people: [],
        isDemo: false,
        error: emptyLocationMessage,
      );
    }
    if (failed) {
      return const NearbyResult(
        people: [],
        isDemo: false,
        error: loadErrorMessage,
      );
    }
    return NearbyResult(people: remote, isDemo: false);
  }
}

/// Arranque: el flavor prod no puede ir con datos de demo.
abstract final class DemoGuard {
  static bool isIllegal({required String flavor, required bool demoMode}) {
    return flavor == 'prod' && demoMode;
  }

  static void assertSafe({required String flavor, required bool demoMode}) {
    if (isIllegal(flavor: flavor, demoMode: demoMode)) {
      throw StateError(
        'El flavor prod no puede arrancar con DEMO_MODE. '
        'Los perfiles de ejemplo no se muestran en producción.',
      );
    }
  }
}
