import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

export 'picaflor_person_card.dart';

/// Superficie card Picaflor — borde fino + sombra soft (también en web).
class PicaflorSurface extends StatelessWidget {
  const PicaflorSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.margin,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: AppColors.cardBorder(isDark: isDark),
        ),
        boxShadow:
            elevated ? AppShadows.card(isDark, web: kIsWeb) : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: content,
      ),
    );
  }
}
