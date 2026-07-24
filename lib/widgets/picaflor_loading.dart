import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'picaflor_skeleton.dart';

export 'picaflor_skeleton.dart';

/// Loader centrado con branding suave.
class PicaflorLoading extends StatelessWidget {
  const PicaflorLoading({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Alias de compatibilidad → [PicaflorSkeleton].
class PicaflorListSkeleton extends StatelessWidget {
  const PicaflorListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return PicaflorSkeleton(itemCount: itemCount);
  }
}
