import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/prefs/key_value_store.dart';

final sharedPreferencesProvider = Provider<KeyValueStore>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe sobreescribirse en main()',
  );
});

/// Preferencia de tema: system / light / dark.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  final KeyValueStore _prefs;

  static ThemeMode _read(KeyValueStore prefs) {
    final raw = prefs.getString(AppConstants.keyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(AppConstants.keyThemeMode, value);
  }

  Future<void> toggleLightDark() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

/// Onboarding completado.
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.keyOnboardingDone) ?? false);

  final KeyValueStore _prefs;

  Future<void> complete() async {
    state = true;
    await _prefs.setBool(AppConstants.keyOnboardingDone, true);
  }

  Future<void> reset() async {
    state = false;
    await _prefs.setBool(AppConstants.keyOnboardingDone, false);
  }
}

final onboardingDoneProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(sharedPreferencesProvider));
});

/// En DEMO el onboarding no debe bloquear el arranque.
/// Override en main() cuando [AppConfig.demoMode].
final demoOnboardingDoneProvider = Provider<bool>((ref) => true);
