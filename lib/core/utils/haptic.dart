import 'package:flutter/services.dart';

/// Feedback háptico sutil y consistente en toda la app.
abstract final class Haptic {
  /// Toque ligero (tap de lista, chip, refresh).
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Confirmación media (enviar mensaje, guardar perfil).
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Acción fuerte (logout, error grave).
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selección (slider, tab, toggle).
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Éxito suave (chat abierto, permiso concedido).
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Warning / denegación.
  static Future<void> warning() async {
    await HapticFeedback.vibrate();
  }
}
