/// Configuración de runtime de Picaflor.
///
/// Por defecto corre en **modo demo** (sin Firebase) hasta que configures
/// credenciales reales o pases `--dart-define=DEMO_MODE=false`.
abstract final class AppConfig {
  /// `true` = datos en memoria, sin red ni Firebase.
  ///
  /// Override:
  /// ```bash
  /// flutter run --dart-define=DEMO_MODE=true
  /// flutter run --dart-define=DEMO_MODE=false
  /// ```
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  static const String demoUid = 'demo_me';
  static const String demoEmail = 'demo@picaflor.cl';
  static const String demoDisplayName = 'Tú (demo)';
  static const String demoBio =
      'Explorando Picaflor en modo demo · sin Firebase';
}
