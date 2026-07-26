import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';

/// Mapa Nearby: radio, yo (approx) y gente cerca (fuzzed).
///
/// Tiles Carto (compatible con OSM data, sin API key; más estable en web
/// que tile.openstreetmap.org que a veces bloquea por User-Agent).
class NearbyMapView extends StatefulWidget {
  const NearbyMapView({
    super.key,
    required this.centerLat,
    required this.centerLon,
    required this.radiusMeters,
    required this.people,
    this.onPersonTap,
  });

  final double centerLat;
  final double centerLon;
  final double radiusMeters;
  final List<NearbyUser> people;
  final void Function(NearbyUser person)? onPersonTap;

  @override
  State<NearbyMapView> createState() => _NearbyMapViewState();
}

/// Alias de compatibilidad.
typedef NearbyMap = NearbyMapView;

class _NearbyMapViewState extends State<NearbyMapView> {
  final _mapController = MapController();

  LatLng get _center => LatLng(widget.centerLat, widget.centerLon);

  double _zoomForRadius(double meters) {
    // Zoom aproximado para que el círculo quepa con margen.
    if (meters <= 400) return 15.2;
    if (meters <= 1000) return 14.2;
    if (meters <= 2500) return 13.2;
    if (meters <= 5000) return 12.4;
    return 11.6;
  }

  @override
  void didUpdateWidget(covariant NearbyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final centerChanged =
        oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLon != widget.centerLon;
    final radiusChanged = oldWidget.radiusMeters != widget.radiusMeters;
    if (centerChanged || radiusChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(_center, _zoomForRadius(widget.radiusMeters));
        } catch (_) {
          // MapController aún no listo en el primer frame.
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final people = widget.people;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoomForRadius(widget.radiusMeters),
              minZoom: 10,
              maxZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Carto CDN (más permisivo en web que tile.openstreetmap.org).
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.picaflor.app.picaflorapp',
                maxNativeZoom: 19,
                keepBuffer: 1,
                panBuffer: 0,
              ),
              // Radio de búsqueda (approx).
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: widget.radiusMeters,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderColor: AppColors.primary.withValues(alpha: 0.45),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              // Gente cerca (coords ya fuzzed en el modelo).
              MarkerLayer(
                markers: [
                  for (final p in people)
                    if (p.user.hasLocation)
                      Marker(
                        point: LatLng(p.user.latitude!, p.user.longitude!),
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: _PersonPin(
                          initials: p.user.initials,
                          isOnline: p.user.isOnline,
                          distanceLabel: LocationService.formatApproxDistance(
                            p.distanceMeters,
                          ),
                          onTap: () => widget.onPersonTap?.call(p),
                        ),
                      ),
                ],
              ),
              // Yo (centro approx).
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: const _MePin(),
                  ),
                ],
              ),
            ],
          ),
          // Leyenda mínima.
          Positioned(
            left: 12,
            bottom: 12,
            child: _MapLegend(count: people.length, isDark: isDark),
          ),
          // Atribución OSM (requerida).
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
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
        ],
      ),
    );
  }
}

class _MePin extends StatelessWidget {
  const _MePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
    );
  }
}

class _PersonPin extends StatelessWidget {
  const _PersonPin({
    required this.initials,
    required this.isOnline,
    required this.distanceLabel,
    this.onTap,
  });

  final String initials;
  final bool isOnline;
  final String distanceLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: distanceLabel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                initials.length > 2 ? initials.substring(0, 2) : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Tú',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count == 1 ? '1 persona' : '$count personas',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
