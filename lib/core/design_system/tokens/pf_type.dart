import 'package:flutter/material.dart';

import 'pf_palette.dart';

/// Inter empaquetada. [fontSize] vive solo en el design system.
abstract final class PfType {
  static const String family = 'Inter';

  static const TextStyle wordmarkOnDark = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.15,
    letterSpacing: -0.4,
    color: PfPalette.textPrimaryDark,
  );

  static TextStyle avatarInitials(double size, Color color) {
    return TextStyle(
      fontFamily: family,
      fontWeight: FontWeight.w600,
      fontSize: size * 0.36,
      height: 1,
      color: color,
    );
  }

  static TextTheme textTheme({required bool isDark}) {
    final primary = isDark ? PfPalette.textPrimaryDark : PfPalette.textPrimary;
    final secondary =
        isDark ? PfPalette.textSecondaryDark : PfPalette.textSecondary;
    final tertiary =
        isDark ? PfPalette.textTertiaryDark : PfPalette.textTertiary;

    TextStyle base(
      FontWeight weight,
      double size,
      double height, {
      Color? color,
      double letterSpacing = 0,
    }) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: const [
          'SF Pro Text',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif',
        ],
        fontWeight: weight,
        fontSize: size,
        height: height / size,
        color: color ?? primary,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      displayLarge: base(FontWeight.w700, 32, 38, letterSpacing: -0.6),
      displayMedium: base(FontWeight.w700, 32, 38, letterSpacing: -0.6),
      displaySmall: base(FontWeight.w700, 28, 34, letterSpacing: -0.5),
      headlineLarge: base(FontWeight.w700, 24, 30, letterSpacing: -0.4),
      headlineMedium: base(FontWeight.w600, 20, 26, letterSpacing: -0.3),
      headlineSmall: base(FontWeight.w600, 17, 22, letterSpacing: -0.2),
      titleLarge: base(FontWeight.w600, 17, 22, letterSpacing: -0.2),
      titleMedium: base(FontWeight.w600, 15, 22, letterSpacing: -0.1),
      titleSmall: base(FontWeight.w600, 13, 18, color: secondary),
      bodyLarge: base(FontWeight.w400, 16, 24),
      bodyMedium: base(FontWeight.w400, 15, 22),
      bodySmall: base(FontWeight.w400, 13, 18, color: secondary),
      labelLarge: base(FontWeight.w600, 13, 16, letterSpacing: 0.1),
      labelMedium: base(
        FontWeight.w500,
        12,
        16,
        color: tertiary,
        letterSpacing: 0.1,
      ),
      labelSmall: base(
        FontWeight.w600,
        11,
        14,
        color: tertiary,
        letterSpacing: 0.6,
      ),
    );
  }
}
