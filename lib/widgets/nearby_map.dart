import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';

/// Mapa Nearby: radio, yo (approx) y gente cerca (fuzzed).
///
/// - Markers custom Tier 1, **clickeables** → [onPersonTap]
/// - Pin “yo” **no** abre chat
/// - Coords siempre referenciales (ya fuzzed en el modelo)
/// - Optimizado para web (tiles livianos, rebuilds controlados)
class NearbyMapView extends StatefulWidget {
  const NearbyMapView({
    super.key,
    required this.centerLat,
    required this.centerLon,
    required this.radiusMeters,
    required this.people,
    this.onPersonTap,
    this.selectedUid,
    this.isBusy = false,
  });

  final double centerLat;
  final double centerLon;
  final double radiusMeters;
  final List<NearbyUser> people;
  final void Function(NearbyUser person)? onPersonTap;

  /// UID del pin resaltado (feedback al seleccionar).
  final String? selectedUid;

  /// Overlay de carga al abrir chat.
  final bool isBusy;

  @override
  State<NearbyMapView> createState() => _NearbyMapViewState();
}

/// Alias de compatibilidad.
typedef NearbyMap = NearbyMapView;

class _NearbyMapViewState extends State<NearbyMapView> {
  final _mapController = MapController();
  bool _mapReady = false;

  LatLng get _center => LatLng(widget.centerLat, widget.centerLon);

  double _zoomForRadius(double meters) {
    if (meters <= 400) return 15.2;
    if (meters <= 1000) return 14.2;
    if (meters <= 2500) return 13.2;
    if (meters <= 5000) return 12.4;
    return 11.6;
  }

  @override
  void didUpdateWidget(covariant NearbyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;

    final centerChanged =
        oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLon != widget.centerLon;
    final radiusChanged = oldWidget.radiusMeters != widget.radiusMeters;

    // Solo mover cámara al soltar radio / cambiar centro — no en cada frame.
    if (centerChanged || radiusChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_mapReady) return;
        try {
          _mapController.move(_center, _zoomForRadius(widget.radiusMeters));
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPersonTap(NearbyUser person) {
    if (widget.isBusy) return;
    widget.onPersonTap?.call(person);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final people = widget.people;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: AppColors.cardBorder(isDark: isDark),
        ),
        boxShadow: AppShadows.card(isDark, web: kIsWeb),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl - 0.5),
        child: Stack(
          children: [
            // RepaintBoundary: el slider no repinta tiles innecesariamente.
            RepaintBoundary(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _zoomForRadius(widget.radiusMeters),
                  minZoom: 10,
                  maxZoom: 17,
                  // Evita pan/zoom “pesado” en web con demasiadas flags.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.scrollWheelZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onMapReady: () {
                    if (mounted) setState(() => _mapReady = true);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.picaflor.app.picaflorapp',
                    maxNativeZoom: 18,
                    // Web: menos tiles en memoria → menos jank.
                    keepBuffer: kIsWeb ? 0 : 1,
                    panBuffer: 0,
                    // Evita re-fetch agresivo al redibujar.
                    tileProvider: NetworkTileProvider(),
                  ),
                  // Halo exterior + relleno: radio elegante estilo fintech.
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _center,
                        radius: widget.radiusMeters,
                        useRadiusInMeter: true,
                        color: AppColors.mapRadiusFill(isDark: isDark),
                        borderColor:
                            AppColors.mapRadiusStroke(isDark: isDark),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                  // Personas (coords ya fuzzed).
                  MarkerLayer(
                    markers: [
                      for (final p in people)
                        if (p.user.hasLocation)
                          Marker(
                            point: LatLng(
                              p.user.latitude!,
                              p.user.longitude!,
                            ),
                            // Hit target generoso; label flota sin mover el pin.
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: _PersonPin(
                              initials: p.user.initials,
                              displayName: p.user.displayName,
                              isOnline: p.user.isOnline,
                              distanceLabel:
                                  LocationService.formatApproxDistance(
                                p.distanceMeters,
                              ),
                              selected: widget.selectedUid == p.user.uid,
                              enabled: !widget.isBusy,
                              onTap: () => _onPersonTap(p),
                            ),
                          ),
                    ],
                  ),
                  // Yo — encima, sin onTap de chat.
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _center,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const _MePin(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              left: 14,
              bottom: 14,
              child: _MapLegend(count: people.length, isDark: isDark),
            ),

            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white)
                      .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDark ? '© OSM · © CARTO' : '© OpenStreetMap',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                ),
              ),
            ),

            // Chip de privacidad (referencial).
            Positioned(
              top: 14,
              left: 14,
              child: _PrivacyChip(isDark: isDark),
            ),

            if (people.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _MapEmptyChip(isDark: isDark),
                  ),
                ),
              ),

            // Loading al abrir chat desde marker.
            if (widget.isBusy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.18),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MePin extends StatelessWidget {
  const _MePin();

  @override
  Widget build(BuildContext context) {
    // Solo referencia visual — no abre chat.
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo exterior
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: AppShadows.mapPin(tint: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonPin extends StatefulWidget {
  const _PersonPin({
    required this.initials,
    required this.displayName,
    required this.isOnline,
    required this.distanceLabel,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String initials;
  final String displayName;
  final bool isOnline;
  final String distanceLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_PersonPin> createState() => _PersonPinState();
}

class _PersonPinState extends State<_PersonPin> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.avatarColorFor(widget.displayName);
    final end = AppColors.avatarColorDark(base);
    final label = widget.initials.length > 2
        ? widget.initials.substring(0, 2)
        : widget.initials;
    final active = widget.selected || _hovered;

    // Área táctil grande + cursor pointer en web + hint de chat.
    return Tooltip(
      message:
          '${widget.displayName} · ${widget.distanceLabel} · toca para chatear',
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [base, end],
                    ),
                    border: Border.all(
                      color: active ? AppColors.primary : Colors.white,
                      width: active ? 3.2 : 2.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.42),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                            ...AppShadows.mapPin(tint: base),
                          ]
                        : AppShadows.mapPin(tint: base),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (widget.isOnline)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (active)
                Positioned(
                  top: 46,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.displayName.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.cardBorder(isDark: isDark),
        ),
        boxShadow: AppShadows.float(isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 13,
            color: isDark ? AppColors.primaryMuted : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Zona aproximada',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.05,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.cardBorder(isDark: isDark),
        ),
        boxShadow: AppShadows.float(isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Tú',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count == 0
                ? 'Sin gente aún'
                : (count == 1
                    ? '1 persona · toca para chatear'
                    : '$count · toca para chatear'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapEmptyChip extends StatelessWidget {
  const _MapEmptyChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.float(isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 18,
            color: isDark ? AppColors.primaryMuted : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Nadie en este radio. Prueba ampliarlo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
