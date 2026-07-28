import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'picaflor_button.dart';

/// Empty state premium — humano, chileno, sin infantilizar.
class PicaflorEmptyState extends StatelessWidget {
  const PicaflorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxW = AppLayout.isWide(context) ? 420.0 : 360.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.18 : 0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: isDark ? AppColors.primaryMuted : AppColors.primary,
                  ),
                ),
              ),
              const Gap(22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const Gap(10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.55,
                    fontSize: 14.5,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const Gap(28),
                PicaflorButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  isExpanded: false,
                  height: 48,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
