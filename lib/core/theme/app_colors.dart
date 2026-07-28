import 'package:flutter/material.dart';

/// Paleta Picaflor Tier 1 — colibrí + fintech (Fintual / BCI / Linear / Mercury).
/// Superficies frías, acento teal calmado, contraste legible light y dark.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  /// Teal principal — un punto más profundo que “startup default”.
  static const Color primary = Color(0xFF0E9B8E);
  static const Color primaryDark = Color(0xFF0A7D72);
  static const Color primarySoft = Color(0xFFE6F7F5);
  static const Color primaryMuted = Color(0xFF6FBFB6);

  static const Color accent = Color(0xFFFF6B4A);
  static const Color accentSoft = Color(0xFFFFF0EC);

  static const Color secondary = Color(0xFF5B6CFF);
  static const Color secondarySoft = Color(0xFFEEF0FF);

  // ── Light ──────────────────────────────────────────────────────────────
  /// Fondo de app (no card) — gris frío con aire.
  static const Color lightBackground = Color(0xFFF3F4F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E5EC);
  static const Color lightDivider = Color(0xFFECEDF1);
  static const Color lightChip = Color(0xFFF0F2F5);

  static const Color lightTextPrimary = Color(0xFF0C0F14);
  static const Color lightTextSecondary = Color(0xFF565E6C);
  static const Color lightTextTertiary = Color(0xFF8A919E);
  static const Color lightTextInverse = Color(0xFFFFFFFF);

  // ── Dark ───────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF090B0F);
  static const Color darkSurface = Color(0xFF11151B);
  static const Color darkSurfaceElevated = Color(0xFF191E27);
  static const Color darkCard = Color(0xFF151A21);
  static const Color darkBorder = Color(0xFF2A313C);
  static const Color darkDivider = Color(0xFF1C222B);
  static const Color darkChip = Color(0xFF1E242E);

  static const Color darkTextPrimary = Color(0xFFF4F5F7);
  static const Color darkTextSecondary = Color(0xFF9AA2AF);
  static const Color darkTextTertiary = Color(0xFF6B7380);
  static const Color darkTextInverse = Color(0xFF0C0F14);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // ── Presence ───────────────────────────────────────────────────────────
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF8A919E);
  static const Color away = Color(0xFFF59E0B);

  // ── Chat ───────────────────────────────────────────────────────────────
  static const Color bubbleMineLight = Color(0xFF0E9B8E);
  static const Color bubbleMineDark = Color(0xFF0A7D72);
  static const Color bubbleOtherLight = Color(0xFFF0F2F5);
  static const Color bubbleOtherDark = Color(0xFF242A34);

  // ── Avatar palette (desaturada-premium) ────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFF0E9B8E),
    Color(0xFF5B6CFF),
    Color(0xFF7C5CFC),
    Color(0xFF0EA5E9),
    Color(0xFF0D9488),
    Color(0xFFDB2777),
    Color(0xFFD97706),
    Color(0xFF4F46E5),
    Color(0xFF059669),
    Color(0xFF7C3AED),
  ];

  static Color avatarColorFor(String seed) {
    if (seed.isEmpty) return avatarPalette.first;
    var hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return avatarPalette[hash.abs() % avatarPalette.length];
  }

  static Color avatarColorDark(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.03).clamp(0.0, 1.0))
        .toColor();
  }

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9B8E), Color(0xFF2BB8A9)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF090B0F), Color(0xFF122825)],
  );

  static Color mapRadiusFill({required bool isDark}) =>
      primary.withValues(alpha: isDark ? 0.14 : 0.08);

  static Color mapRadiusStroke({required bool isDark}) =>
      primary.withValues(alpha: isDark ? 0.48 : 0.32);

  static Color cardBorder({required bool isDark}) => isDark
      ? darkBorder.withValues(alpha: 0.9)
      : lightBorder.withValues(alpha: 0.95);

  static Color chipFill({required bool isDark}) =>
      isDark ? darkChip : lightChip;
}
