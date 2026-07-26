import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Feedback háptico sutil. En **web** es no-op (evita jank / colgadas).
abstract final class Haptic {
  static Future<void> light() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> medium() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> success() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> warning() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
