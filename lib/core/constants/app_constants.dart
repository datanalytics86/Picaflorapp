/// Constantes generales de la app.
abstract final class AppConstants {
  static const String appName = 'Picaflor';
  static const String appTagline = 'Gente cerca, charlas reales';

  // SharedPreferences keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode = 'theme_mode';
  static const String keySearchRadius = 'search_radius_m';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';

  // Auth
  static const int minPasswordLength = 6;
  static const int minDisplayNameLength = 2;
  static const int maxDisplayNameLength = 40;
  static const int maxBioLength = 160;

  // Chat
  static const int messagesPageSize = 40;
  static const Duration typingDebounce = Duration(milliseconds: 400);

  // UI
  static const double horizontalPadding = 20;
  static const double cardRadius = 20;
  static const Duration shortAnimation = Duration(milliseconds: 220);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
}
