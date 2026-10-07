import 'package:flutter/material.dart';

import '../design_system/tokens/pf_palette.dart';
import '../design_system/tokens/pf_type.dart';

/// Tipografía v2. Los tamaños se definen en [PfType].
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) =>
      PfType.textTheme(isDark: isDark);

  static TextStyle get brandTitle => const TextStyle(
        fontFamily: PfType.family,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.4,
        color: PfPalette.brand,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: PfType.family,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: PfType.family,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: PfPalette.textTertiary,
      );

  static TextStyle get overline => const TextStyle(
        fontFamily: PfType.family,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.6,
      );
}
