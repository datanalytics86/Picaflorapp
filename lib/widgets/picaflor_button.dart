import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum PicaflorButtonVariant { primary, secondary, outline, ghost, danger }

/// Botón principal de la app — pill suave, loading y variantes.
class PicaflorButton extends StatelessWidget {
  const PicaflorButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PicaflorButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final PicaflorButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double height;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    final button = switch (variant) {
      PicaflorButtonVariant.primary => ElevatedButton(
          onPressed: _enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 24 : 20,
              vertical: 14,
            ),
          ),
          child: child,
        ),
      PicaflorButtonVariant.secondary => ElevatedButton(
          onPressed: _enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
          ),
          child: child,
        ),
      PicaflorButtonVariant.outline => OutlinedButton(
          onPressed: _enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
          ),
          child: child,
        ),
      PicaflorButtonVariant.ghost => TextButton(
          onPressed: _enabled ? onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
          ),
          child: child,
        ),
      PicaflorButtonVariant.danger => ElevatedButton(
          onPressed: _enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
          ),
          child: child,
        ),
    };

    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: variant == PicaflorButtonVariant.outline ||
                  variant == PicaflorButtonVariant.ghost
              ? AppColors.primary
              : Colors.white,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(label, style: AppTypography.button),
        ],
      );
    }

    return Text(label);
  }
}

/// Botón social (Google, etc.) con borde suave.
class PicaflorSocialButton extends StatelessWidget {
  const PicaflorSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: AppTypography.button.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
