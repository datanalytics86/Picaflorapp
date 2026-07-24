import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/haptic.dart';

/// Diálogo premium para pedir ubicación (o redirigir a Ajustes).
class PicaflorPermissionDialog extends StatelessWidget {
  const PicaflorPermissionDialog({
    super.key,
    this.title = 'Necesitamos tu ubicación',
    this.message =
        'Así te mostramos gente cerca en Santiago. '
        'Solo usamos una zona aproximada, nunca tu punto exacto.',
    this.primaryLabel = 'Permitir',
    this.secondaryLabel = 'Ahora no',
    this.isPermanentlyDenied = false,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final bool isPermanentlyDenied;

  /// Muestra el diálogo y devuelve `true` si el usuario acepta.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    bool isPermanentlyDenied = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PicaflorPermissionDialog(
        title: title ??
            (isPermanentlyDenied
                ? 'Ubicación bloqueada'
                : 'Necesitamos tu ubicación'),
        message: message ??
            (isPermanentlyDenied
                ? 'Ábrela en Ajustes del teléfono para ver gente cerca.'
                : 'Así te mostramos gente cerca en Santiago. '
                    'Solo usamos una zona aproximada, nunca tu punto exacto.'),
        primaryLabel: isPermanentlyDenied ? 'Ir a Ajustes' : 'Permitir',
        isPermanentlyDenied: isPermanentlyDenied,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () {
                Haptic.selection();
                Navigator.of(context).pop(false);
              },
              child: Text(secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
