import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';

void main() {
  const subscriptionService = SubscriptionService();

  group('SubscriptionService - Tier Resolution', () {
    test('resolves free and pro subscription tiers', () {
      expect(subscriptionService.getTier(false), equals(SubscriptionTier.free));
      expect(subscriptionService.getTier(true), equals(SubscriptionTier.pro));
    });
  });

  group('SubscriptionService - Scan Quota Gates', () {
    test('enforces 3 scans per day limit on Free tier', () {
      expect(
        subscriptionService.canPerformScan(currentScansToday: 0, isPro: false),
        isTrue,
      );
      expect(
        subscriptionService.canPerformScan(currentScansToday: 2, isPro: false),
        isTrue,
      );
      expect(
        subscriptionService.canPerformScan(currentScansToday: 3, isPro: false),
        isFalse,
      );
      expect(
        subscriptionService.canPerformScan(currentScansToday: 4, isPro: false),
        isFalse,
      );
    });

    test('allows unlimited scans on Pro tier regardless of scan count', () {
      expect(
        subscriptionService.canPerformScan(currentScansToday: 3, isPro: true),
        isTrue,
      );
      expect(
        subscriptionService.canPerformScan(currentScansToday: 100, isPro: true),
        isTrue,
      );
    });

    test('calculates remaining scans accurately', () {
      expect(
        subscriptionService.getRemainingScans(currentScansToday: 1, isPro: false),
        equals(2),
      );
      expect(
        subscriptionService.getRemainingScans(currentScansToday: 3, isPro: false),
        equals(0),
      );
      expect(
        subscriptionService.getRemainingScans(currentScansToday: 5, isPro: false),
        equals(0),
      );
      expect(
        subscriptionService.getRemainingScans(currentScansToday: 50, isPro: true),
        greaterThan(1000),
      );
    });

    test('checkScanQuota provides detailed status and upgrade prompt when exceeded', () {
      final allowedStatus = subscriptionService.checkScanQuota(
        currentScansToday: 1,
        isPro: false,
      );
      expect(allowedStatus.isAllowed, isTrue);
      expect(allowedStatus.remaining, equals(2));
      expect(allowedStatus.upgradePrompt, isNull);

      final blockedStatus = subscriptionService.checkScanQuota(
        currentScansToday: 3,
        isPro: false,
      );
      expect(blockedStatus.isAllowed, isFalse);
      expect(blockedStatus.remaining, equals(0));
      expect(blockedStatus.upgradePrompt, contains('Upgrade to Pro'));
    });
  });

  group('SubscriptionService - Pond & Feature Quotas', () {
    test('enforces 3 ponds limit on Free tier and unlimited on Pro', () {
      expect(
        subscriptionService.canAddPond(currentPondCount: 2, isPro: false),
        isTrue,
      );
      expect(
        subscriptionService.canAddPond(currentPondCount: 3, isPro: false),
        isFalse,
      );
      expect(
        subscriptionService.canAddPond(currentPondCount: 10, isPro: true),
        isTrue,
      );
    });

    test('enforces feed calculations and report quotas on Free tier', () {
      expect(
        subscriptionService.canPerformFeedCalculation(
          currentCalcsThisMonth: 4,
          isPro: false,
        ),
        isTrue,
      );
      expect(
        subscriptionService.canPerformFeedCalculation(
          currentCalcsThisMonth: 5,
          isPro: false,
        ),
        isFalse,
      );
      expect(
        subscriptionService.canExportReport(
          currentReportsThisMonth: 2,
          isPro: false,
        ),
        isTrue,
      );
      expect(
        subscriptionService.canExportReport(
          currentReportsThisMonth: 3,
          isPro: false,
        ),
        isFalse,
      );
    });

    test('generates upgrade prompt for various feature keys', () {
      expect(
        subscriptionService.getUpgradePrompt('scans'),
        contains('PrawnGuard Pro'),
      );
      expect(
        subscriptionService.getUpgradePrompt('ponds'),
        contains('PrawnGuard Pro'),
      );
      expect(
        subscriptionService.getUpgradePrompt('feed_ai'),
        contains('PrawnGuard Pro'),
      );
    });
  });
}
