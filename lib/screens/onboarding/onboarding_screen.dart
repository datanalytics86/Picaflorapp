import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/picaflor_button.dart';

/// Onboarding de máximo 2 pantallas — limpio y directo.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardData(
      icon: Icons.people_alt_rounded,
      title: 'Gente real,\ncerca de ti',
      subtitle:
          'Descubre personas cerca en Santiago. '
          'Sin ruido: solo cercanía y buena onda.',
      accent: AppColors.primary,
      soft: AppColors.primarySoft,
    ),
    _OnboardData(
      icon: Icons.chat_bubble_rounded,
      title: 'Charlas simples,\naltiro',
      subtitle:
          'Abre un chat, coordina un café o solo saluda. '
          'Tú controlas tu visibilidad.',
      accent: AppColors.accent,
      soft: AppColors.accentSoft,
    ),
  ];

  Future<void> _finish() async {
    await Haptic.success();
    await ref.read(onboardingDoneProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    Haptic.selection();
    if (_page < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Saltar'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl - 4,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isDark
                                ? data.accent.withValues(alpha: 0.15)
                                : data.soft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.icon,
                            size: 64,
                            color: data.accent,
                          ),
                        ),
                        const Spacer(flex: 2),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.55,
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl - 4,
                0,
                AppSpacing.xxl - 4,
                AppSpacing.xxl - 4,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          borderRadius: AppSpacing.pillRadius,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PicaflorButton(
                    label: isLast ? 'Empezar' : 'Siguiente',
                    onPressed: _next,
                    icon: isLast ? Icons.arrow_forward_rounded : null,
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

class _OnboardData {
  const _OnboardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.soft,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color soft;
}
