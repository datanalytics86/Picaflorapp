import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
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
// flutter_map se carga SOLO al abrir la pestaña Mapa (evita freeze al boot).
import '../../widgets/nearby_map.dart' deferred as map_lib;
import '../../widgets/picaflor_card.dart';
import '../../widgets/picaflor_empty_state.dart';
import '../../widgets/picaflor_permission_dialog.dart';
import '../../widgets/picaflor_skeleton.dart';

/// Gente cerca — lista + mapa. Tier 1 · performance-first · demo-safe.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _askedPermission = false;

  /// 0 = lista, 1 = mapa.
  int _viewMode = 0;

  /// Lazy map: no monta tiles hasta la primera visita.
  bool _mapEverOpened = false;

  /// Library de flutter_map cargada (deferred).
  bool _mapLibReady = false;
  bool _mapLibLoading = false;

  /// Valor del slider mientras se arrastra (solo UI local).
  late double _sliderRadius;

  Timer? _radiusDebounce;

  /// UID seleccionado en mapa (feedback visual).
  String? _selectedMapUid;

  /// Abriendo chat (deshabilita taps, muestra spinner).
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(locationControllerProvider).radiusMeters;
    _sliderRadius = initial;
    // Demo: LocationController ya tiene Santiago en el constructor.
    // Cero work en el primer frame.
    if (!AppConfig.demoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapProd());
    } else if (kDebugMode) {
      debugPrint('📍 NearbyScreen DEMO: skip bootstrap GPS');
    }
  }

  @override
  void dispose() {
    _radiusDebounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapProd() async {
    final controller = ref.read(locationControllerProvider.notifier);

    try {
      await controller.checkPermission().timeout(const Duration(seconds: 5));
    } catch (_) {}

    final state = ref.read(locationControllerProvider);

    if (state.permission == LocationPermissionStatus.granted) {
      try {
        await controller.refresh().timeout(const Duration(seconds: 14));
      } catch (_) {}
      return;
    }

    if (!_askedPermission) {
      _askedPermission = true;
      if (!mounted) return;
      // Diálogo solo tras el primer frame usable.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) await _requestWithDialog();
    }
  }

  Future<void> _requestWithDialog() async {
    if (AppConfig.demoMode) {
      await ref.read(locationControllerProvider.notifier).refresh();
      return;
    }

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

  void _onRadiusChanged(double value) {
    // Solo UI: NO toca Riverpod ni nearby en cada tick.
    setState(() => _sliderRadius = value);
  }

  void _onRadiusChangeEnd(double value) {
    Haptic.light();
    _commitRadius(value);
  }

  void _commitRadius(double value) {
    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(locationControllerProvider.notifier).setRadius(value);
    });
  }

  Future<void> _setViewMode(int mode) async {
    Haptic.selection();
    if (mode == 0) {
      setState(() {
        _viewMode = 0;
        _selectedMapUid = null;
      });
      return;
    }

    // Mapa: carga deferred de flutter_map ANTES de montar el widget.
    setState(() {
      _viewMode = 1;
      _mapEverOpened = true;
    });

    if (_mapLibReady || _mapLibLoading) return;
    _mapLibLoading = true;
    if (kDebugMode) debugPrint('🗺️ loading flutter_map deferred…');
    try {
      await map_lib.loadLibrary().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _mapLibReady = true;
        _mapLibLoading = false;
      });
      if (kDebugMode) debugPrint('🗺️ flutter_map ready');
    } catch (e) {
      debugPrint('🗺️ map library load failed: $e');
      if (!mounted) return;
      setState(() => _mapLibLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el mapa.')),
      );
    }
  }

  Future<void> _openChat(String otherUid, {bool fromMap = false}) async {
    if (_openingChat) return;
    if (otherUid.isEmpty) return;

    final meUid = ref.read(authServiceProvider).currentUid;
    if (meUid == null) {
      if (kDebugMode) debugPrint('💬 openChat: sin sesión');
      return;
    }
    if (otherUid == meUid) return;

    setState(() {
      _openingChat = true;
      if (fromMap) _selectedMapUid = otherUid;
    });

    // Haptic no-op en web; no bloquear navegación.
    unawaited(Haptic.medium());

    try {
      if (kDebugMode) debugPrint('💬 openChat → $otherUid');
      // Timeout corto: en demo es local; si cuelga, no dejar UI muerta.
      final chat = await ref
          .read(chatControllerProvider.notifier)
          .openChatWith(otherUid)
          .timeout(const Duration(seconds: 2));

      if (!mounted) return;

      if (chat == null) {
        final err = ref.read(chatControllerProvider).error;
        if (kDebugMode) debugPrint('💬 openChat null: $err');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'No se pudo abrir el chat.')),
        );
        setState(() {
          _openingChat = false;
          _selectedMapUid = null;
        });
        return;
      }

      if (kDebugMode) debugPrint('💬 push chat ${chat.id}');
      setState(() {
        _openingChat = false;
        _selectedMapUid = null;
      });
      // Navegar en el siguiente microtask para soltar el frame del press.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      context.push(AppRoutes.chatPath(chat.id, otherUid: otherUid));
    } catch (e) {
      if (kDebugMode) debugPrint('💬 openChat error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el chat.')),
      );
      setState(() {
        _openingChat = false;
        _selectedMapUid = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watches selectivos: menos rebuilds al mover el slider.
    final isLoadingLoc = ref.watch(
      locationControllerProvider.select((s) => s.isLoading),
    );
    final hasLocation = ref.watch(
      locationControllerProvider.select((s) => s.hasLocation),
    );
    final locationError = ref.watch(
      locationControllerProvider.select((s) => s.error),
    );
    final isPermanent = ref.watch(
      locationControllerProvider.select(
        (s) => s.isPermanentlyDenied || s.isServiceDisabled,
      ),
    );
    final centerLat = ref.watch(
      locationControllerProvider.select(
        (s) => s.location?.latitude ?? SantiagoBounds.centerLatitude,
      ),
    );
    final centerLon = ref.watch(
      locationControllerProvider.select(
        (s) => s.location?.longitude ?? SantiagoBounds.centerLongitude,
      ),
    );

    final nearby = ref.watch(nearbyUsersProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final firstName = me?.displayName.split(' ').first;

    // LocationState ligero solo para _ListBody (permisos).
    final location = ref.watch(locationControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: firstName != null ? 'Hola, $firstName' : 'Cerca de ti',
              subtitle: 'Gente alrededor · zona aproximada',
              isRefreshing: isLoadingLoc,
              viewMode: _viewMode,
              onViewModeChanged: _setViewMode,
              onRefresh: _onRefresh,
            ),
            _RadiusCard(
              radiusMeters: _sliderRadius,
              onChanged: _onRadiusChanged,
              onChangeEnd: _onRadiusChangeEnd,
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
            if (locationError != null && !hasLocation)
              _LocationBanner(
                message: locationError,
                isPermanent: isPermanent,
                onAction: _requestWithDialog,
              ),
            Expanded(
              // IndexedStack: no destruye el mapa al volver a lista.
              // Lazy: el mapa solo se monta tras la primera visita.
              child: IndexedStack(
                index: _viewMode,
                sizing: StackFit.expand,
                children: [
                  _ListBody(
                    location: location,
                    nearby: nearby,
                    onRefresh: _onRefresh,
                    onRequestPermission: _requestWithDialog,
                    onOpenChat: (uid) => _openChat(uid),
                  ),
                  _mapEverOpened
                      ? _MapBody(
                          centerLat: centerLat,
                          centerLon: centerLon,
                          displayRadiusMeters: _sliderRadius,
                          nearby: nearby,
                          selectedUid: _selectedMapUid,
                          isBusy: _openingChat,
                          mapLibReady: _mapLibReady,
                          mapLibLoading: _mapLibLoading,
                          onRefresh: _onRefresh,
                          onOpenChat: (uid) =>
                              _openChat(uid, fromMap: true),
                        )
                      : const SizedBox.shrink(),
                ],
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
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool isRefreshing;
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wide = AppLayout.isWide(context);
    final px = AppLayout.pageX(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.isDesktop(context)
              ? AppLayout.contentMaxWide
              : AppLayout.contentMax,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(px, wide ? 28 : 20, px, wide ? 14 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.55,
                        height: 1.1,
                        fontSize: wide ? 26 : 22,
                      ),
                    ),
                    SizedBox(height: wide ? 6 : 5),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.35,
                        fontSize: wide ? 14 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ViewModeToggle(
                viewMode: viewMode,
                onChanged: onViewModeChanged,
              ),
              const SizedBox(width: 8),
              _RefreshButton(
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  final int viewMode;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showLabels = AppLayout.isWide(context);

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightChip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: Icons.view_list_rounded,
            label: 'Lista',
            selected: viewMode == 0,
            showLabel: showLabels,
            onTap: () => onChanged(0),
          ),
          _ToggleSegment(
            icon: Icons.map_rounded,
            label: 'Mapa',
            selected: viewMode == 1,
            showLabel: showLabels,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDark ? AppColors.primaryMuted : AppColors.primaryDark;
    final idleColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 34,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
            width: showLabel ? null : 38,
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.lightSurface)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected && !isDark
                  ? [
                      BoxShadow(
                        color:
                            const Color(0xFF0C0F14).withValues(alpha: 0.07),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? selectedColor : idleColor,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                      color: selected ? selectedColor : idleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Actualizar',
      child: Material(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightChip,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isRefreshing ? null : () => onRefresh(),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: isRefreshing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.primaryMuted
                            : AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
            ),
          ),
        ),
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
    final label = LocationPrivacy.formatApproxDistance(radiusMeters);
    final px = AppLayout.pageX(context);
    final wide = AppLayout.isWide(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.isDesktop(context)
              ? AppLayout.contentMaxWide
              : AppLayout.contentMax,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(px, 0, px, AppSpacing.sm),
          child: PicaflorSurface(
            elevated: true,
            padding: EdgeInsets.fromLTRB(
              wide ? 18 : 16,
              wide ? 14 : 12,
              wide ? 18 : 16,
              wide ? 8 : 6,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.primaryMuted
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Radio de búsqueda',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.primarySoft,
                        borderRadius: AppSpacing.pillRadius,
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.primaryMuted
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: isDark
                        ? AppColors.darkBorder
                        : AppColors.primary.withValues(alpha: 0.1),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 1.5,
                      pressedElevation: 3,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    trackShape: const RoundedRectSliderTrackShape(),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                  child: Row(
                    children: [
                      Text(
                        LocationPrivacy.formatApproxDistance(
                          SantiagoBounds.minSearchRadiusMeters,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontSize: 10.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        LocationPrivacy.formatApproxDistance(
                          SantiagoBounds.maxSearchRadiusMeters,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    final px = AppLayout.pageX(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.isDesktop(context)
              ? AppLayout.contentMaxWide
              : AppLayout.contentMax,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(px, 0, px, AppSpacing.xs),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.info.withValues(alpha: 0.12)
                  : AppColors.infoSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppColors.info.withValues(alpha: 0.2)
                    : AppColors.info.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: isDark ? AppColors.info : AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ejemplos mientras llega gente real cerca',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final px = AppLayout.pageX(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(px, 0, px, AppSpacing.xs),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppColors.warning.withValues(alpha: 0.22)
                    : AppColors.warning.withValues(alpha: 0.14),
              ),
            ),
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ),
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
    final px = AppLayout.pageX(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(px, 0, px, AppSpacing.xs),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppColors.warning.withValues(alpha: 0.22)
                    : AppColors.warning.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(message, style: theme.textTheme.bodySmall),
                ),
                TextButton(
                  onPressed: onAction,
                  child: Text(isPermanent ? 'Ajustes' : 'Permitir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
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
    // Demo: nunca skeleton por GPS.
    if (!AppConfig.demoMode &&
        location.isLoading &&
        !location.hasLocation) {
      return const PicaflorSkeleton(itemCount: 6);
    }

    return nearby.when(
      loading: () => AppConfig.demoMode
          ? const SizedBox.shrink()
          : const PicaflorSkeleton(itemCount: 6),
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
                const SizedBox(height: 72),
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

        final px = AppLayout.pageX(context);
        final wide = AppLayout.isWide(context);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              px,
              AppSpacing.xs,
              px,
              wide ? AppSpacing.xxl : AppSpacing.xl,
            ),
            itemCount: people.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: wide ? 14 : AppSpacing.listGap),
            itemBuilder: (context, index) {
              final item = people[index];
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppLayout.contentMax),
                  child: PicaflorPersonCard(
                    user: item.user,
                    distanceLabel: LocationPrivacy.formatApproxDistance(
                      item.distanceMeters,
                    ),
                    onTap: () => onOpenChat(item.user.uid),
                    onChat: () => onOpenChat(item.user.uid),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.centerLat,
    required this.centerLon,
    required this.displayRadiusMeters,
    required this.nearby,
    required this.selectedUid,
    required this.isBusy,
    required this.mapLibReady,
    required this.mapLibLoading,
    required this.onRefresh,
    required this.onOpenChat,
  });

  final double centerLat;
  final double centerLon;
  final double displayRadiusMeters;
  final AsyncValue<NearbyResult> nearby;
  final String? selectedUid;
  final bool isBusy;
  final bool mapLibReady;
  final bool mapLibLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String otherUid) onOpenChat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final px = AppLayout.pageX(context);
    final wide = AppLayout.isWide(context);
    final desktop = AppLayout.isDesktop(context);

    Widget mapContent;
    if (!mapLibReady) {
      mapContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              mapLibLoading ? 'Preparando mapa…' : 'Mapa no disponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            ),
          ],
        ),
      );
    } else {
      mapContent = nearby.when(
        loading: () => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
        error: (_, __) => PicaflorEmptyState(
          icon: Icons.map_outlined,
          title: 'Mapa no disponible',
          subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: onRefresh,
        ),
        data: (result) {
          return map_lib.NearbyMapView(
            centerLat: centerLat,
            centerLon: centerLon,
            radiusMeters: displayRadiusMeters,
            people: result.people,
            selectedUid: selectedUid,
            isBusy: isBusy,
            onPersonTap: (p) => onOpenChat(p.user.uid),
          );
        },
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWide),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            px,
            AppSpacing.xs,
            px,
            wide ? AppSpacing.lg : AppSpacing.md,
          ),
          child: desktop
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.mapMinHeightDesktop,
                  ),
                  child: SizedBox.expand(child: mapContent),
                )
              : mapContent,
        ),
      ),
    );
  }
}
