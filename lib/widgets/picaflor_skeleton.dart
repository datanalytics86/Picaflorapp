import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Skeleton shimmer reutilizable (listas Cerca / Chats).
class PicaflorSkeleton extends StatelessWidget {
  const PicaflorSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 92,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE8EBF0);
    final highlight =
        isDark ? AppColors.darkBorder : const Color(0xFFF5F6F8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          AppSpacing.xs,
          AppSpacing.pageX,
          AppSpacing.xl,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const PicaflorPersonCardSkeleton(),
      ),
    );
  }
}

/// Una fila skeleton con forma de person card.
class PicaflorPersonCardSkeleton extends StatelessWidget {
  const PicaflorPersonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE8EBF0);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque rectangular genérico con shimmer.
class PicaflorBoxSkeleton extends StatelessWidget {
  const PicaflorBoxSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppSpacing.radiusMd,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE8EBF0);
    final highlight =
        isDark ? AppColors.darkBorder : const Color(0xFFF5F6F8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
