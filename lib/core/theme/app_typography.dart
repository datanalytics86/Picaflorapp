import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía Picaflor — Poppins en nativo; en **web** usa fuentes del sistema
/// para no bloquear la UI esperando fonts.gstatic.com.
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
      // Web: sin fetch de red (GoogleFonts runtime puede colgar el primer frame).
      if (kIsWeb) {
        return TextStyle(
          fontFamily: 'Segoe UI',
          fontFamilyFallback: const [
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

      return GoogleFonts.poppins(
        fontWeight: weight,
        fontSize: size,
        height: height,
        color: color ?? primary,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      displayLarge: base(FontWeight.w700, 40, 1.15, letterSpacing: -0.8),
      displayMedium: base(FontWeight.w700, 32, 1.2, letterSpacing: -0.5),
      displaySmall: base(FontWeight.w600, 28, 1.25, letterSpacing: -0.3),
      headlineLarge: base(FontWeight.w600, 24, 1.3, letterSpacing: -0.2),
      headlineMedium: base(FontWeight.w600, 20, 1.35),
      headlineSmall: base(FontWeight.w600, 18, 1.35),
      titleLarge: base(FontWeight.w600, 17, 1.4),
      titleMedium: base(FontWeight.w500, 15, 1.4),
      titleSmall: base(FontWeight.w500, 13, 1.4, color: secondary),
      bodyLarge: base(FontWeight.w400, 16, 1.55),
      bodyMedium: base(FontWeight.w400, 14, 1.5),
      bodySmall: base(FontWeight.w400, 12, 1.45, color: secondary),
      labelLarge: base(FontWeight.w600, 15, 1.2, letterSpacing: 0.1),
      labelMedium: base(FontWeight.w500, 13, 1.2, color: secondary),
      labelSmall:
          base(FontWeight.w500, 11, 1.2, color: tertiary, letterSpacing: 0.2),
    );
  }

  static TextStyle get brandTitle {
    if (kIsWeb) {
      return const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.primary,
      );
    }
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.2,
      letterSpacing: -0.4,
      color: AppColors.primary,
    );
  }

  static TextStyle get button {
    if (kIsWeb) {
      return const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.2,
        letterSpacing: 0.1,
      );
    }
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.2,
      letterSpacing: 0.1,
    );
  }

  static TextStyle get caption {
    if (kIsWeb) {
      return const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.4,
      );
    }
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.4,
    );
  }

  static TextStyle get overline {
    if (kIsWeb) {
      return const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.2,
        letterSpacing: 0.8,
      );
    }
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 1.2,
      letterSpacing: 0.8,
    );
  }
}
