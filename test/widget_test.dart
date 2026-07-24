import 'package:flutter_test/flutter_test.dart';

import 'package:picaflorapp/core/constants/app_constants.dart';
import 'package:picaflorapp/core/constants/santiago_bounds.dart';

void main() {
  test('app constants and Santiago bounds are coherent', () {
    expect(AppConstants.appName, 'Picaflor');
    expect(SantiagoBounds.defaultSearchRadiusMeters, greaterThan(0));
    expect(SantiagoBounds.minLatitude, lessThan(SantiagoBounds.maxLatitude));
    expect(SantiagoBounds.minLongitude, lessThan(SantiagoBounds.maxLongitude));
  });
}
