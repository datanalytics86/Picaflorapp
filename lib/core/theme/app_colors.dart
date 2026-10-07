import 'package:flutter/material.dart';

import '../design_system/tokens/pf_palette.dart';

/// Alias estable de la paleta v2. Los literales viven en [PfPalette].
abstract final class AppColors {
  static const Color primary = PfPalette.brand;
  static const Color primaryDark = PfPalette.brandPressed;
  static const Color primarySoft = PfPalette.brandSubtle;
  static const Color primaryMuted = PfPalette.onBrandSubtle;

  static const Color accent = PfPalette.accent;
  static const Color accentSoft = PfPalette.accentSoft;

  static const Color secondary = PfPalette.secondary;
  static const Color secondarySoft = PfPalette.secondarySoft;

  static const Color lightBackground = PfPalette.surfaceSubtle;
  static const Color lightSurface = PfPalette.canvas;
  static const Color lightSurfaceElevated = PfPalette.canvas;
  static const Color lightCard = PfPalette.canvas;
  static const Color lightBorder = PfPalette.border;
  static const Color lightDivider = PfPalette.border;
  static const Color lightChip = PfPalette.surfaceSubtle;

  static const Color lightTextPrimary = PfPalette.textPrimary;
  static const Color lightTextSecondary = PfPalette.textSecondary;
  static const Color lightTextTertiary = PfPalette.textTertiary;
  static const Color lightTextInverse = PfPalette.onBrand;

  static const Color darkBackground = PfPalette.canvasDark;
  static const Color darkSurface = PfPalette.surfaceDark;
  static const Color darkSurfaceElevated = PfPalette.surface2Dark;
  static const Color darkCard = PfPalette.surfaceDark;
  static const Color darkBorder = PfPalette.borderDark;
  static const Color darkDivider = PfPalette.borderDark;
  static const Color darkChip = PfPalette.surface2Dark;

  static const Color darkTextPrimary = PfPalette.textPrimaryDark;
  static const Color darkTextSecondary = PfPalette.textSecondaryDark;
  static const Color darkTextTertiary = PfPalette.textTertiaryDark;
  static const Color darkTextInverse = PfPalette.onBrandDark;

  static const Color success = PfPalette.success;
  static const Color successSoft = PfPalette.successBg;
  static const Color warning = PfPalette.warning;
  static const Color warningSoft = PfPalette.warningBg;
  static const Color error = PfPalette.danger;
  static const Color errorSoft = PfPalette.dangerBg;
  static const Color info = PfPalette.info;
  static const Color infoSoft = PfPalette.infoBg;

  static const Color online = PfPalette.success;
  static const Color offline = PfPalette.textTertiary;
  static const Color away = PfPalette.warning;

  static const Color bubbleMineLight = PfPalette.brand;
  static const Color bubbleMineDark = PfPalette.brandDark;
  static const Color bubbleOtherLight = PfPalette.surfaceSubtle;
  static const Color bubbleOtherDark = PfPalette.bubbleOtherDark;

  static const Color onBrandLight = PfPalette.onBrand;
  static const Color onBrandDark = PfPalette.onBrandDark;

  static const Color primaryContainerDark = PfPalette.primaryContainerDark;
  static const Color secondaryContainerDark = PfPalette.secondaryContainerDark;
  static const Color onSecondaryContainerDark = PfPalette.onSecondaryContainerDark;
  static const Color accentContainerDark = PfPalette.accentContainerDark;
  static const Color errorContainerDark = PfPalette.errorContainerDark;
  static const Color inkShadow = PfPalette.inkShadow;

  static const List<Color> avatarPalette = PfPalette.avatarPalette;

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

  static const LinearGradient primaryGradient = PfPalette.primaryGradient;
  static const LinearGradient splashGradient = PfPalette.splashGradient;

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
