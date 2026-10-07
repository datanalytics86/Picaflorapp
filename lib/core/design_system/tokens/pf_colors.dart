import 'package:flutter/material.dart';

import 'pf_palette.dart';

/// Acceso: `Theme.of(context).extension<PfColors>()!` o [PfBuildContext.pf].
@immutable
class PfColors extends ThemeExtension<PfColors> {
  const PfColors({
    required this.canvas,
    required this.surfaceSubtle,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.onBrand,
    required this.brandPressed,
    required this.brandSubtle,
    required this.onBrandSubtle,
    required this.plus,
    required this.plusSubtle,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.info,
  });

  final Color canvas;
  final Color surfaceSubtle;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand;
  final Color onBrand;
  final Color brandPressed;
  final Color brandSubtle;
  final Color onBrandSubtle;
  final Color plus;
  final Color plusSubtle;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color info;

  static const light = PfColors(
    canvas: PfPalette.canvas,
    surfaceSubtle: PfPalette.surfaceSubtle,
    border: PfPalette.border,
    borderStrong: PfPalette.borderStrong,
    textPrimary: PfPalette.textPrimary,
    textSecondary: PfPalette.textSecondary,
    textTertiary: PfPalette.textTertiary,
    brand: PfPalette.brand,
    onBrand: PfPalette.onBrand,
    brandPressed: PfPalette.brandPressed,
    brandSubtle: PfPalette.brandSubtle,
    onBrandSubtle: PfPalette.onBrandSubtle,
    plus: PfPalette.plus,
    plusSubtle: PfPalette.plusSubtle,
    success: PfPalette.success,
    successBg: PfPalette.successBg,
    warning: PfPalette.warning,
    warningBg: PfPalette.warningBg,
    danger: PfPalette.danger,
    dangerBg: PfPalette.dangerBg,
    info: PfPalette.info,
  );

  static const dark = PfColors(
    canvas: PfPalette.canvasDark,
    surfaceSubtle: PfPalette.surfaceDark,
    border: PfPalette.borderDark,
    borderStrong: PfPalette.borderStrongDark,
    textPrimary: PfPalette.textPrimaryDark,
    textSecondary: PfPalette.textSecondaryDark,
    textTertiary: PfPalette.textTertiaryDark,
    brand: PfPalette.brandDark,
    onBrand: PfPalette.onBrandDark,
    brandPressed: PfPalette.brand,
    brandSubtle: PfPalette.primaryContainerDark,
    onBrandSubtle: PfPalette.brandDark,
    plus: PfPalette.plusDark,
    plusSubtle: PfPalette.surface2Dark,
    success: PfPalette.successDark,
    successBg: PfPalette.surface2Dark,
    warning: PfPalette.warningBg,
    warningBg: PfPalette.surface2Dark,
    danger: PfPalette.dangerDark,
    dangerBg: PfPalette.errorContainerDark,
    info: PfPalette.info,
  );

  @override
  PfColors copyWith({
    Color? canvas,
    Color? surfaceSubtle,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brand,
    Color? onBrand,
    Color? brandPressed,
    Color? brandSubtle,
    Color? onBrandSubtle,
    Color? plus,
    Color? plusSubtle,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
    Color? info,
  }) {
    return PfColors(
      canvas: canvas ?? this.canvas,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandPressed: brandPressed ?? this.brandPressed,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      onBrandSubtle: onBrandSubtle ?? this.onBrandSubtle,
      plus: plus ?? this.plus,
      plusSubtle: plusSubtle ?? this.plusSubtle,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      info: info ?? this.info,
    );
  }

  @override
  PfColors lerp(ThemeExtension<PfColors>? other, double t) {
    if (other is! PfColors) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return PfColors(
      canvas: m(canvas, other.canvas),
      surfaceSubtle: m(surfaceSubtle, other.surfaceSubtle),
      border: m(border, other.border),
      borderStrong: m(borderStrong, other.borderStrong),
      textPrimary: m(textPrimary, other.textPrimary),
      textSecondary: m(textSecondary, other.textSecondary),
      textTertiary: m(textTertiary, other.textTertiary),
      brand: m(brand, other.brand),
      onBrand: m(onBrand, other.onBrand),
      brandPressed: m(brandPressed, other.brandPressed),
      brandSubtle: m(brandSubtle, other.brandSubtle),
      onBrandSubtle: m(onBrandSubtle, other.onBrandSubtle),
      plus: m(plus, other.plus),
      plusSubtle: m(plusSubtle, other.plusSubtle),
      success: m(success, other.success),
      successBg: m(successBg, other.successBg),
      warning: m(warning, other.warning),
      warningBg: m(warningBg, other.warningBg),
      danger: m(danger, other.danger),
      dangerBg: m(dangerBg, other.dangerBg),
      info: m(info, other.info),
    );
  }
}

class PfThemeAccess {
  const PfThemeAccess(this.colors, this.type);
  final PfColors colors;
  final TextTheme type;
}

extension PfBuildContext on BuildContext {
  PfThemeAccess get pf {
    final theme = Theme.of(this);
    return PfThemeAccess(
      theme.extension<PfColors>() ?? PfColors.light,
      theme.textTheme,
    );
  }
}
