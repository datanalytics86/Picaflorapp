import 'package:flutter_test/flutter_test.dart';
import 'package:picaflorapp/core/config/app_config.dart';
import 'package:picaflorapp/core/constants/santiago_bounds.dart';
import 'package:picaflorapp/data/demo_nearby.dart';
import 'package:picaflorapp/services/location_service.dart';

void main() {
  group('LocationService demo / privacy', () {
    test('demoMode is default true', () {
      expect(AppConfig.demoMode, isTrue);
    });

    test('santiagoCenterApprox is fuzzed and in bounds', () {
      final approx = LocationService.santiagoCenterApprox();
      expect(approx.isInSantiago, isTrue);
      // Fuzz redondea; no debe ser el valor crudo con muchos decimales “GPS”.
      expect(
        approx.latitude,
        LocationService.approximateCoordinate(SantiagoBounds.centerLatitude),
      );
      expect(
        approx.longitude,
        LocationService.approximateCoordinate(SantiagoBounds.centerLongitude),
      );
      expect(approx.accuracyMeters, greaterThanOrEqualTo(100));
    });

    test('getApproxLocation in demo never needs GPS', () async {
      final service = LocationService();
      final loc = await service.getApproxLocation();
      expect(loc.isInSantiago, isTrue);
      final status = await service.checkPermissionStatus();
      expect(status, LocationPermissionStatus.granted);
      final req = await service.requestPermission();
      expect(req, LocationPermissionStatus.granted);
    });

    test('formatApproxDistance never shows raw coords', () {
      expect(LocationService.formatApproxDistance(40), 'muy cerca');
      expect(LocationService.formatApproxDistance(150), 'cerca');
      final label = LocationService.formatApproxDistance(320);
      expect(label.contains('m') || label.contains('cerca'), isTrue);
      expect(label.contains('-33'), isFalse);
    });
  });

  group('DemoNearby radius filter', () {
    test('people filtered by radius', () {
      final all = DemoNearby.people(
        originLat: SantiagoBounds.centerLatitude,
        originLon: SantiagoBounds.centerLongitude,
      );
      expect(all, isNotEmpty);

      final tight = all.where((p) => p.distanceMeters <= 200).toList();
      final wide = all.where((p) => p.distanceMeters <= 10000).toList();
      expect(tight.length, lessThanOrEqualTo(wide.length));
      expect(wide.length, all.length);

      // Todos tienen coords (fuzzed en el modelo demo).
      for (final p in all) {
        expect(p.user.hasLocation, isTrue);
      }
    });
  });
}
