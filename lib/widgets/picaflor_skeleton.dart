import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Skeleton — en DEMO/web sin shimmer animado (evita jank).
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
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE4E7EE);
    final highlight =
        isDark ? AppColors.darkBorder : const Color(0xFFF3F4F8);
    final px = AppLayout.pageX(context);

    final list = ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(px, AppSpacing.xs, px, AppSpacing.xl),
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (_, __) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
          child: const PicaflorPersonCardSkeleton(),
        ),
      ),
    );

    if (AppConfig.demoMode || kIsWeb) return list;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: list,
    );
  }
}

class PicaflorPersonCardSkeleton extends StatelessWidget {
  const PicaflorPersonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill =
        isDark ? AppColors.darkCard : AppColors.lightCard;
    final bone = isDark ? AppColors.darkBorder : const Color(0xFFD6DAE2);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: AppColors.cardBorder(isDark: isDark),
        ),
        boxShadow: AppShadows.card(isDark, web: kIsWeb),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: bone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: bone,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 18,
                      width: 48,
                      decoration: BoxDecoration(
                        color: bone,
                        borderRadius: AppSpacing.pillRadius,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 11,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bone,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 160,
                  decoration: BoxDecoration(
                    color: bone,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 22,
                      width: 56,
                      decoration: BoxDecoration(
                        color: bone,
                        borderRadius: AppSpacing.pillRadius,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 22,
                      width: 72,
                      decoration: BoxDecoration(
                        color: bone,
                        borderRadius: AppSpacing.pillRadius,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bone,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}

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
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE4E7EE);
    final highlight =
        isDark ? AppColors.darkBorder : const Color(0xFFF3F4F8);

    if (AppConfig.demoMode || kIsWeb) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

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
