import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/santiago_bounds.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/nearby_provider.dart';
import '../../router/app_router.dart';
import '../../services/location_service.dart';
import '../../widgets/picaflor_card.dart';
import '../../widgets/picaflor_empty_state.dart';
import '../../widgets/picaflor_permission_dialog.dart';
import '../../widgets/picaflor_skeleton.dart';

/// Gente cerca — LocationService real + Firestore + demos de respaldo.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _askedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final controller = ref.read(locationControllerProvider.notifier);
    await controller.checkPermission();
    final state = ref.read(locationControllerProvider);

    if (state.permission == LocationPermissionStatus.granted) {
      await controller.refresh();
      return;
    }

    if (!_askedPermission) {
      _askedPermission = true;
      if (!mounted) return;
      // Pequeña pausa para que la UI asiente.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) await _requestWithDialog();
    }
  }

  Future<void> _requestWithDialog() async {
    final location = ref.read(locationControllerProvider);
    final permanent = location.isPermanentlyDenied;
    final serviceOff = location.isServiceDisabled;

    final accepted = await PicaflorPermissionDialog.show(
      context,
      isPermanentlyDenied: permanent || serviceOff,
      title: serviceOff
          ? 'Ubicación apagada'
          : (permanent ? 'Ubicación bloqueada' : null),
      message: serviceOff
          ? 'Activa la ubicación del teléfono para ver gente cerca.'
          : null,
    );

    if (!accepted || !mounted) return;

    if (permanent || serviceOff) {
      await ref.read(locationControllerProvider.notifier).openSettings();
      return;
    }

    await Haptic.light();
    await ref.read(locationControllerProvider.notifier).refresh();
  }

  Future<void> _onRefresh() async {
    await Haptic.light();
    await ref.read(locationControllerProvider.notifier).refresh();
    ref.invalidate(nearbyUsersProvider);
  }

  Future<void> _openChat(String otherUid) async {
    await Haptic.medium();
    final chat = await ref
        .read(chatControllerProvider.notifier)
        .openChatWith(otherUid);
    if (!mounted) return;

    if (chat == null) {
      final err = ref.read(chatControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'No se pudo abrir el chat.'),
        ),
      );
      return;
    }

    context.push(AppRoutes.chatPath(chat.id, otherUid: otherUid));
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final nearby = ref.watch(nearbyUsersProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final firstName = me?.displayName.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: firstName != null ? 'Hola, $firstName' : 'Cerca de ti',
              subtitle: 'Gente alrededor · zona aproximada',
              isRefreshing: location.isLoading,
              onRefresh: _onRefresh,
            ),
            _RadiusCard(
              radiusMeters: location.radiusMeters,
              onChanged: (v) {
                Haptic.selection();
                ref.read(locationControllerProvider.notifier).setRadius(v);
              },
              onChangeEnd: (_) {
                Haptic.light();
                ref.invalidate(nearbyUsersProvider);
              },
            ),
            nearby.when(
              data: (result) {
                if (result.isDemo && result.people.isNotEmpty) {
                  return const _DemoBanner();
                }
                if (result.error != null) {
                  return _InfoBanner(message: result.error!);
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (location.error != null && !location.hasLocation)
              _LocationBanner(
                message: location.error!,
                isPermanent: location.isPermanentlyDenied ||
                    location.isServiceDisabled,
                onAction: _requestWithDialog,
              ),
            Expanded(
              child: _Body(
                location: location,
                nearby: nearby,
                onRefresh: _onRefresh,
                onRequestPermission: _requestWithDialog,
                onOpenChat: _openChat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isRefreshing ? null : () => onRefresh(),
            tooltip: 'Actualizar',
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _RadiusCard extends StatelessWidget {
  const _RadiusCard({
    required this.radiusMeters,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double radiusMeters;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        AppSpacing.xs,
        AppSpacing.pageX,
        AppSpacing.xs,
      ),
      child: PicaflorSurface(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Radio',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  LocationService.formatApproxDistance(radiusMeters),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor:
                    isDark ? AppColors.darkBorder : AppColors.primarySoft,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                trackHeight: 4,
              ),
              child: Slider(
                value: radiusMeters.clamp(
                  SantiagoBounds.minSearchRadiusMeters,
                  SantiagoBounds.maxSearchRadiusMeters,
                ),
                min: SantiagoBounds.minSearchRadiusMeters,
                max: SantiagoBounds.maxSearchRadiusMeters,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A3A) : AppColors.infoSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: isDark ? AppColors.info : AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ejemplos mientras llega gente real cerca',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3D2A15) : AppColors.warningSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(message, style: theme.textTheme.bodySmall),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.message,
    required this.isPermanent,
    required this.onAction,
  });

  final String message;
  final bool isPermanent;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3D2A15) : AppColors.warningSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_outlined,
                color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
            TextButton(
              onPressed: onAction,
              child: Text(isPermanent ? 'Ajustes' : 'Permitir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.location,
    required this.nearby,
    required this.onRefresh,
    required this.onRequestPermission,
    required this.onOpenChat,
  });

  final LocationState location;
  final AsyncValue<NearbyResult> nearby;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function(String otherUid) onOpenChat;

  @override
  Widget build(BuildContext context) {
    if (location.isLoading && !location.hasLocation) {
      return const PicaflorSkeleton(itemCount: 6);
    }

    return nearby.when(
      loading: () => const PicaflorSkeleton(itemCount: 6),
      error: (_, __) => PicaflorEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar',
        subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
        actionLabel: 'Reintentar',
        onAction: onRefresh,
      ),
      data: (result) {
        final people = result.people;
        if (people.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 64),
                PicaflorEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'Nadie cerca… por ahora',
                  subtitle:
                      'Amplía el radio o vuelve en un rato. Santiago se mueve.',
                  actionLabel: location.needsPermission
                      ? 'Activar ubicación'
                      : 'Actualizar',
                  onAction: location.needsPermission
                      ? onRequestPermission
                      : onRefresh,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageX,
              AppSpacing.xs,
              AppSpacing.pageX,
              AppSpacing.xl,
            ),
            itemCount: people.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = people[index];
              return PicaflorPersonCard(
                user: item.user,
                distanceLabel: LocationService.formatApproxDistance(
                  item.distanceMeters,
                ),
                onTap: () => onOpenChat(item.user.uid),
                onChat: () => onOpenChat(item.user.uid),
              );
            },
          ),
        );
      },
    );
  }
}
