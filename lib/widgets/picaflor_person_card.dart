import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/haptic.dart';
import '../models/user_model.dart';
import 'picaflor_avatar.dart';

/// Card de persona cercana — minimalista, con distancia aproximada.
class PicaflorPersonCard extends StatelessWidget {
  const PicaflorPersonCard({
    super.key,
    required this.user,
    required this.distanceLabel,
    this.onTap,
    this.onChat,
  });

  final UserModel user;
  final String distanceLabel;
  final VoidCallback? onTap;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        onTap: () {
          Haptic.light();
          onTap?.call();
        },
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              PicaflorAvatar(
                photoUrl: user.photoUrl,
                displayName: user.displayName,
                size: 56,
                isOnline: user.isOnline,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _DistanceChip(label: distanceLabel),
                      ],
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        user.bio,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.interests.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xxs + 2,
                        runSpacing: AppSpacing.xxs,
                        children: user.interests.take(3).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.primarySoft,
                              borderRadius: AppSpacing.pillRadius,
                            ),
                            child: Text(
                              interest,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (onChat != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () {
                    Haptic.medium();
                    onChat?.call();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  tooltip: 'Escribirle',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A28) : AppColors.primarySoft,
        borderRadius: AppSpacing.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
