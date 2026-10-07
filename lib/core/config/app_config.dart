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
  /// flutter build web --dart-define=DEMO_MODE=false --release
  /// ```
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  /// Build de release (Flutter define `dart.vm.product` en release).
  static const bool isRelease = bool.fromEnvironment('dart.vm.product');

  /// URL pública de privacidad (Play Store / App Store / web).
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://picaflorapp.web.app/privacidad',
  );

  /// URL de términos de uso.
  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://picaflor.app/terminos',
  );

  /// Soporte / contacto.
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'hola@picaflor.app',
  );

  static const String demoUid = 'demo_me';
  static const String demoEmail = 'demo@picaflor.cl';
  static const String demoDisplayName = 'Tú (demo)';
  static const String demoBio =
      'Explorando Picaflor en modo demo · sin Firebase';

  /// `dev` (demo), `staging` o `prod`. Proyectos Firebase separados.
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Saludo con aceptación. Encendido por defecto (Guideline 1.2 / acoso).
  static const bool wavesEnabled = bool.fromEnvironment(
    'WAVES_ENABLED',
    defaultValue: true,
  );

  /// Plus se construye apagado hasta que haya liquidez (Remote Config / define).
  static const bool plusEnabled = bool.fromEnvironment(
    'PLUS_ENABLED',
    defaultValue: false,
  );

  /// Tiles del mapa. Vacío = CARTO con atribución visible.
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: '',
  );

  static const String mapTileUrlDark = String.fromEnvironment(
    'MAP_TILE_URL_DARK',
    defaultValue: '',
  );

  static const String region = 'southamerica-east1';
}
