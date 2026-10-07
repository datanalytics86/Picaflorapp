import 'package:flutter_test/flutter_test.dart';
import 'package:picaflorapp/core/analytics/app_analytics.dart';
import 'package:picaflorapp/core/design_system/tokens/contrast.dart';
import 'package:picaflorapp/core/design_system/tokens/pf_palette.dart';
import 'package:picaflorapp/core/prefs/key_value_store.dart';
import 'package:picaflorapp/core/privacy/age_gate.dart';
import 'package:picaflorapp/core/privacy/buckets.dart';
import 'package:picaflorapp/core/privacy/nearby_policy.dart';
import 'package:picaflorapp/core/privacy/wave_quota.dart';
import 'package:picaflorapp/models/user_model.dart';
import 'package:picaflorapp/services/user_service.dart';

void main() {
  test('prod flavor cannot boot in demo mode', () {
    expect(DemoGuard.isIllegal(flavor: 'prod', demoMode: true), isTrue);
    expect(DemoGuard.isIllegal(flavor: 'prod', demoMode: false), isFalse);
    expect(DemoGuard.isIllegal(flavor: 'dev', demoMode: true), isFalse);
    expect(
      () => DemoGuard.assertSafe(flavor: 'prod', demoMode: true),
      throwsStateError,
    );
  });

  test('production nearby never fills with demo people', () {
    const demo = [
      NearbyUser(
        user: UserModel(uid: 'demo_a', email: '', displayName: 'A'),
        distanceMeters: 100,
      ),
    ];
    final failed = NearbyPolicy.resolve(
      demoMode: false,
      hasLocation: true,
      failed: true,
      remote: const [],
      demoPeople: demo,
    );
    expect(failed.people, isEmpty);
    expect(failed.isDemo, isFalse);
    expect(failed.error, isNotNull);

    final noLoc = NearbyPolicy.resolve(
      demoMode: false,
      hasLocation: false,
      failed: false,
      remote: demo,
      demoPeople: demo,
    );
    expect(noLoc.people, isEmpty);
    expect(noLoc.isDemo, isFalse);
  });

  test('age gate uses calendar years', () {
    final today = DateTime(2026, 10, 6);
    expect(AgeGate.isAdult(DateTime(2008, 10, 6), today), isTrue);
    expect(AgeGate.isAdult(DateTime(2008, 10, 7), today), isFalse);
    expect(AgeGate.isAdult(DateTime(2010, 1, 1), today), isFalse);
    expect(AgeGate.isAdult(DateTime(2027, 1, 1), today), isFalse);
  });

  test('distance and activity buckets', () {
    expect(DistanceBuckets.fromMeters(40), DistanceBuckets.veryClose);
    expect(DistanceBuckets.fromMeters(300), DistanceBuckets.m300);
    expect(DistanceBuckets.fromMeters(900), DistanceBuckets.m800);
    expect(DistanceBuckets.fromMeters(2000), DistanceBuckets.km2);
    expect(DistanceBuckets.fromMeters(5000), DistanceBuckets.km5);
    expect(DistanceBuckets.fromMeters(9000), DistanceBuckets.km10);

    final now = DateTime(2026, 10, 6, 12);
    expect(
      ActivityBuckets.fromLastActive(now.subtract(const Duration(minutes: 5)), now),
      ActivityBuckets.now,
    );
    expect(
      ActivityBuckets.fromLastActive(now.subtract(const Duration(hours: 5)), now),
      ActivityBuckets.today,
    );
    expect(
      ActivityBuckets.fromLastActive(now.subtract(const Duration(days: 3)), now),
      ActivityBuckets.thisWeek,
    );
    expect(
      ActivityBuckets.fromLastActive(now.subtract(const Duration(days: 9)), now),
      ActivityBuckets.inactive,
    );
  });

  test('wave quota and CLP format', () {
    expect(WaveQuota.canSend(sentToday: 19, plus: false), isTrue);
    expect(WaveQuota.canSend(sentToday: 20, plus: false), isFalse);
    expect(WaveQuota.canSend(sentToday: 100, plus: true), isTrue);
    expect(WaveQuota.radiusCap(plus: false), 5000);
    expect(WaveQuota.radiusCap(plus: true), 10000);
    expect(ClpFormat.pesos(4990), r'$4.990');
    expect(ClpFormat.pesos(29990), r'$29.990');
  });

  test('v2 tokens pass WCAG AA for text', () {
    expect(contrastRatio(PfPalette.onBrand, PfPalette.brand), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textPrimary, PfPalette.canvas), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textSecondary, PfPalette.canvas), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textTertiary, PfPalette.canvas), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textTertiary, PfPalette.surfaceSubtle), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.onBrand, PfPalette.success), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.onBrand, PfPalette.danger), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.onBrand, PfPalette.accent), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.onBrand, PfPalette.secondary), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.onBrandDark, PfPalette.brandDark), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textPrimaryDark, PfPalette.canvasDark), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(PfPalette.textTertiaryDark, PfPalette.surfaceDark), greaterThanOrEqualTo(4.5));
  });

  test('analytics drops events without consent and rejects pii keys', () {
    final analytics = MemoryAnalytics();
    analytics.track(const AnalyticsEvent('wave_sent', {'has_note': false}));
    expect(analytics.events, isEmpty);
    analytics.consent = true;
    analytics.track(const AnalyticsEvent('wave_sent', {'has_note': false}));
    expect(analytics.events, hasLength(1));
    expect(
      () => analytics.track(const AnalyticsEvent('bad', {'latitude': 1})),
      throwsArgumentError,
    );
  });

  test('memory prefs do not mark onboarding done', () async {
    final store = MemoryKeyValueStore();
    expect(store.getBool('onboarding_done'), isNull);
    await store.setBool('onboarding_done', false);
    expect(store.getBool('onboarding_done'), isFalse);
  });
}
