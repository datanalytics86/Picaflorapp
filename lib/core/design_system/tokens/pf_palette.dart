import 'package:flutter/material.dart';

/// Tokens de color v2. Único lugar con literales `Color(0x…)`.
///
/// Contrastes calculados con la fórmula WCAG 2.x (ver `contrast.dart` y tests).
@immutable
abstract final class PfPalette {
  // Light
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF6F7F9);
  static const Color border = Color(0xFFE6E8EC);
  static const Color borderStrong = Color(0xFF8A94A6);
  static const Color textPrimary = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF4A5363);
  static const Color textTertiary = Color(0xFF667085);
  static const Color brand = Color(0xFF0B7A6F);
  static const Color brandPressed = Color(0xFF096A60);
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color brandSubtle = Color(0xFFE8F5F3);
  static const Color onBrandSubtle = Color(0xFF075E55);
  static const Color plus = Color(0xFF5B3FD6);
  static const Color plusSubtle = Color(0xFFF1EDFF);
  static const Color onPlus = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF127A3E);
  static const Color successBg = Color(0xFFE7F6EC);
  static const Color warning = Color(0xFF8A5A00);
  static const Color warningBg = Color(0xFFFFF4DB);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color info = Color(0xFF1D5FD1);
  static const Color infoBg = Color(0xFFE8F0FE);

  // Dark
  static const Color canvasDark = Color(0xFF0B0F14);
  static const Color surfaceDark = Color(0xFF12171E);
  static const Color surface2Dark = Color(0xFF19202A);
  static const Color borderDark = Color(0xFF2A313C);
  static const Color borderStrongDark = Color(0xFF6B7689);
  static const Color textPrimaryDark = Color(0xFFF2F4F7);
  static const Color textSecondaryDark = Color(0xFFA3ACB9);
  static const Color textTertiaryDark = Color(0xFF8B95A5);
  static const Color brandDark = Color(0xFF3CC2B3);
  static const Color onBrandDark = Color(0xFF04201C);
  static const Color plusDark = Color(0xFFA78BFA);
  static const Color dangerDark = Color(0xFFF97066);
  static const Color successDark = Color(0xFF4ADE80);

  // Containers used by ColorScheme (not text-on-white).
  static const Color primaryContainerDark = Color(0xFF0F3D38);
  static const Color secondaryContainerDark = Color(0xFF1E2440);
  static const Color onSecondaryContainerDark = Color(0xFFB8C0FF);
  static const Color accentContainerDark = Color(0xFF3D1F18);
  static const Color errorContainerDark = Color(0xFF3D1515);
  static const Color bubbleOtherDark = Color(0xFF242A34);

  /// Secondary action. Dark enough for white label (replaces #5B6CFF).
  static const Color secondary = Color(0xFF2F3FA8);
  static const Color secondarySoft = Color(0xFFEEF0FF);

  /// Warm accent, white label passes AA (replaces #FF6B4A).
  static const Color accent = Color(0xFF9A3412);
  static const Color accentSoft = Color(0xFFFFF0EC);

  static const Color inkShadow = Color(0xFF0B1220);

  static const List<Color> avatarPalette = [
    Color(0xFF0B7A6F),
    Color(0xFF2F3FA8),
    Color(0xFF5B3FD6),
    Color(0xFF1D5FD1),
    Color(0xFF127A3E),
    Color(0xFF9A3412),
    Color(0xFF8A5A00),
    Color(0xFF3D4ED8),
    Color(0xFF075E55),
    Color(0xFF4C1D95),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B7A6F), Color(0xFF149688)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0F14), Color(0xFF12312C)],
  );
}
