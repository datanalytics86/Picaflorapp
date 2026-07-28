import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/haptic.dart';
import '../models/user_model.dart';
import 'picaflor_avatar.dart';

/// Person card Tier 1 — fintech chileno: aire, jerarquía, CTA claro.
/// En desktop no se estira: el padre limita el ancho (AppLayout.contentMax).
class PicaflorPersonCard extends StatefulWidget {
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
  State<PicaflorPersonCard> createState() => _PicaflorPersonCardState();
}

class _PicaflorPersonCardState extends State<PicaflorPersonCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = widget.user;
    final wide = AppLayout.isWide(context);
    final avatarSize = wide ? 66.0 : 58.0;

    // Nativo: micro-press. Web: hover sutil (sin scale janky).
    final scale = (!kIsWeb && _pressed) ? 0.987 : 1.0;
    final elevated = _hovered || _pressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: elevated && !isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.cardBorder(isDark: isDark),
              width: 1,
            ),
            boxShadow: elevated
                ? AppShadows.cardHover(isDark)
                : AppShadows.card(isDark, web: kIsWeb),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: InkWell(
              onTap: widget.onTap == null
                  ? null
                  : () {
                      Haptic.light();
                      widget.onTap!();
                    },
              onTapDown: widget.onTap == null || kIsWeb
                  ? null
                  : (_) => setState(() => _pressed = true),
              onTapUp: widget.onTap == null || kIsWeb
                  ? null
                  : (_) => setState(() => _pressed = false),
              onTapCancel: widget.onTap == null || kIsWeb
                  ? null
                  : () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              splashColor: AppColors.primary.withValues(alpha: 0.05),
              highlightColor: AppColors.primary.withValues(alpha: 0.02),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 20 : 16,
                  wide ? 18 : 15,
                  wide ? 16 : 12,
                  wide ? 18 : 15,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PicaflorAvatar(
                      photoUrl: user.photoUrl,
                      displayName: user.displayName,
                      size: avatarSize,
                      isOnline: user.isOnline,
                    ),
                    SizedBox(width: wide ? 16 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  user.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: wide ? 16.5 : 15.5,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _DistanceChip(label: widget.distanceLabel),
                            ],
                          ),
                          if (user.isOnline) ...[
                            const SizedBox(height: 4),
                            Text(
                              'En línea',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.online,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                                letterSpacing: 0.05,
                              ),
                            ),
                          ],
                          if (user.bio.isNotEmpty) ...[
                            SizedBox(height: user.isOnline ? 5 : 6),
                            Text(
                              user.bio,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13.2,
                                height: 1.42,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (user.interests.isNotEmpty) ...[
                            const SizedBox(height: 11),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: user.interests
                                  .take(wide ? 4 : 3)
                                  .map((i) => _InterestTag(label: i))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.onChat != null) ...[
                      SizedBox(width: wide ? 14 : 8),
                      _ChatButton(
                        onPressed: () {
                          Haptic.medium();
                          widget.onChat!();
                        },
                        showLabel: wide,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  const _InterestTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primarySoft.withValues(alpha: 0.95),
        borderRadius: AppSpacing.pillRadius,
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.15,
          letterSpacing: 0.02,
          color: isDark ? AppColors.primaryMuted : AppColors.primaryDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppColors.chipFill(isDark: isDark),
        borderRadius: AppSpacing.pillRadius,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.6)
              : AppColors.lightBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            size: 11,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -0.1,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    required this.onPressed,
    this.showLabel = false,
  });

  final VoidCallback onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primarySoft;
    final fg = isDark ? AppColors.primaryMuted : AppColors.primaryDark;

    if (showLabel) {
      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_rounded, size: 16, color: fg),
                const SizedBox(width: 7),
                Text(
                  'Chatear',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Chatear',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 18,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
