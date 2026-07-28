import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/chat_provider.dart';

/// Shell adaptativo:
/// - Móvil: bottom NavigationBar
/// - Tablet/PC: NavigationRail lateral (producto real, no app estirada)
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    Haptic.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(totalUnreadProvider).valueOrNull ?? 0;
    final useRail = AppLayout.useNavRail(context);
    final extended = AppLayout.isDesktop(context);
    final index = navigationShell.currentIndex;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopRail(
              selectedIndex: index,
              unread: unread,
              extended: extended,
              isDark: isDark,
              onDestinationSelected: _onTap,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0C0F14).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _onTap,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.near_me_outlined),
              selectedIcon: Icon(Icons.near_me_rounded),
              label: 'Cerca',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Chats',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selectedIndex,
    required this.unread,
    required this.extended,
    required this.isDark,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int unread;
  final bool extended;
  final bool isDark;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: extended ? AppLayout.railExtendedWidth : AppLayout.railWidth,
      color: bg,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                extended ? 18 : 0,
                22,
                extended ? 12 : 0,
                18,
              ),
              child: extended
                  ? Row(
                      children: [
                        const _BrandMark(size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Picaflor',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.35,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Santiago',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(child: _BrandMark(size: 34)),
            ),
            Expanded(
              child: NavigationRail(
                extended: extended,
                minWidth: AppLayout.railWidth,
                minExtendedWidth: AppLayout.railExtendedWidth,
                backgroundColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                groupAlignment: -0.9,
                labelType: NavigationRailLabelType.none,
                indicatorColor: isDark
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.primarySoft,
                selectedIconTheme: IconThemeData(
                  color:
                      isDark ? AppColors.primaryMuted : AppColors.primaryDark,
                  size: 22,
                ),
                unselectedIconTheme: IconThemeData(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  size: 22,
                ),
                selectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color:
                      isDark ? AppColors.primaryMuted : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  fontWeight: FontWeight.w500,
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.near_me_outlined),
                    selectedIcon: const Icon(Icons.near_me_rounded),
                    label: Text(
                      'Cerca',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text(unread > 99 ? '99+' : '$unread'),
                      child: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text(unread > 99 ? '99+' : '$unread'),
                      child: const Icon(Icons.chat_bubble_rounded),
                    ),
                    label: Text(
                      'Chats',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: Text(
                      'Perfil',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (extended)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Zona aproximada',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'P',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
