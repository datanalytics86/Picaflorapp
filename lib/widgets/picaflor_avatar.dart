import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Avatar circular con inicial de respaldo e indicador de presencia.
class PicaflorAvatar extends StatelessWidget {
  const PicaflorAvatar({
    super.key,
    this.photoUrl,
    this.displayName = '',
    this.size = 48,
    this.isOnline,
    this.showBorder = false,
    this.onTap,
  });

  final String? photoUrl;
  final String displayName;
  final double size;
  final bool? isOnline;
  final bool showBorder;
  final VoidCallback? onTap;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_, __) => _InitialsPlaceholder(
                  initials: _initials,
                  size: size,
                  isDark: isDark,
                ),
                errorWidget: (_, __, ___) => _InitialsPlaceholder(
                  initials: _initials,
                  size: size,
                  isDark: isDark,
                ),
              )
            : _InitialsPlaceholder(
                initials: _initials,
                size: size,
                isDark: isDark,
              ),
      ),
    );

    if (isOnline != null) {
      final dotSize = (size * 0.28).clamp(8.0, 14.0);
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
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  width: 2,
                ),
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

class _InitialsPlaceholder extends StatelessWidget {
  const _InitialsPlaceholder({
    required this.initials,
    required this.size,
    required this.isDark,
  });

  final String initials;
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E3A36), Color(0xFF16302C)]
              : const [Color(0xFFE6F7F5), Color(0xFFD0EFEA)],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          height: 1,
        ),
      ),
    );
  }
}
