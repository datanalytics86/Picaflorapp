import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía Picaflor Tier 1 — system fonts (web-safe), tracking en títulos.
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) {
    final Color primary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color tertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    TextStyle base(
      FontWeight weight,
      double size,
      double height, {
      Color? color,
      double letterSpacing = 0,
    }) {
      return TextStyle(
        fontFamily: kIsWeb ? 'Segoe UI' : null,
        fontFamilyFallback: const [
          'SF Pro Text',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif',
        ],
        fontWeight: weight,
        fontSize: size,
        height: height,
        color: color ?? primary,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      displayLarge: base(FontWeight.w700, 40, 1.1, letterSpacing: -1.1),
      displayMedium: base(FontWeight.w700, 32, 1.12, letterSpacing: -0.8),
      displaySmall: base(FontWeight.w700, 28, 1.18, letterSpacing: -0.55),
      headlineLarge: base(FontWeight.w700, 24, 1.22, letterSpacing: -0.45),
      headlineMedium: base(FontWeight.w700, 20, 1.25, letterSpacing: -0.4),
      headlineSmall: base(FontWeight.w600, 18, 1.28, letterSpacing: -0.3),
      titleLarge: base(FontWeight.w600, 17, 1.32, letterSpacing: -0.22),
      titleMedium: base(FontWeight.w600, 15.5, 1.32, letterSpacing: -0.18),
      titleSmall: base(FontWeight.w500, 13, 1.35, color: secondary),
      bodyLarge: base(FontWeight.w400, 16, 1.55),
      bodyMedium: base(FontWeight.w400, 14, 1.5),
      bodySmall: base(FontWeight.w400, 13, 1.45, color: secondary),
      labelLarge: base(FontWeight.w600, 14, 1.2, letterSpacing: 0.02),
      labelMedium: base(FontWeight.w500, 12, 1.25, color: secondary),
      labelSmall:
          base(FontWeight.w500, 11, 1.2, color: tertiary, letterSpacing: 0.12),
    );
  }

  static TextStyle get brandTitle => const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.12,
        letterSpacing: -0.55,
        color: AppColors.primary,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.2,
        letterSpacing: 0.02,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.4,
      );

  static TextStyle get overline => const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.2,
        letterSpacing: 0.55,
      );
}
