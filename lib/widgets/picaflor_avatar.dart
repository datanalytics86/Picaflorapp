import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';

/// Avatar premium — iniciales con gradiente, anillo sutil, presencia discreta.
class PicaflorAvatar extends StatelessWidget {
  const PicaflorAvatar({
    super.key,
    this.photoUrl,
    this.displayName = '',
    this.size = 48,
    this.isOnline,
    this.showBorder = false,
    this.onTap,
    this.useBrandGradient = false,
  });

  final String? photoUrl;
  final String displayName;
  final double size;
  final bool? isOnline;
  final bool showBorder;
  final VoidCallback? onTap;
  final bool useBrandGradient;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      if (parts.first.isEmpty) return '?';
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color get _baseColor => AppColors.avatarColorFor(displayName);

  bool get _usePhoto {
    if (AppConfig.demoMode || kIsWeb) return false;
    return photoUrl != null && photoUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 2,
              )
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: _baseColor.withValues(alpha: isDark ? 0.22 : 0.14),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.05),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipOval(
        child: _usePhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _Initials(
                  initials: _initials,
                  size: size,
                  baseColor: _baseColor,
                  useBrandGradient: useBrandGradient,
                ),
                frameBuilder: (context, child, frame, sync) {
                  if (sync || frame != null) return child;
                  return _Initials(
                    initials: _initials,
                    size: size,
                    baseColor: _baseColor,
                    useBrandGradient: useBrandGradient,
                  );
                },
              )
            : _Initials(
                initials: _initials,
                size: size,
                baseColor: _baseColor,
                useBrandGradient: useBrandGradient,
              ),
      ),
    );

    if (isOnline != null) {
      final dotSize = (size * 0.24).clamp(9.0, 14.0);
      final ringColor = isDark ? AppColors.darkCard : AppColors.lightCard;
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isOnline! ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2.2),
                boxShadow: isOnline!
                    ? [
                        BoxShadow(
                          color: AppColors.online.withValues(alpha: 0.4),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      );
    }
    return avatar;
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.size,
    required this.baseColor,
    this.useBrandGradient = false,
  });

  final String initials;
  final double size;
  final Color baseColor;
  final bool useBrandGradient;

  @override
  Widget build(BuildContext context) {
    final start = useBrandGradient ? AppColors.primary : baseColor;
    final end = useBrandGradient
        ? const Color(0xFF2BB8A9)
        : AppColors.avatarColorDark(baseColor);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}
