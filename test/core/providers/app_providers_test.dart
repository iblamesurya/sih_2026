import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/providers/app_providers.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';
import 'package:prawn_guard/features/finance/models/finance_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riverpod app_providers.dart State Management & clearAllUserData', () {
    test('Core service providers instantiate expected singleton / engine types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(alertSystemProvider), isA<AlertSystem>());
      expect(container.read(subscriptionServiceProvider), isA<SubscriptionService>());
    });

    test('Initial domain state providers are cleanly initialized', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentUserProvider), isNull);
      expect(container.read(currentFarmProvider), isNull);
      expect(container.read(pondListProvider), isEmpty);
      expect(container.read(waterLogsProvider), isEmpty);
      expect(container.read(feedLogsProvider), isEmpty);
      expect(container.read(diseaseScansProvider), isEmpty);
      expect(container.read(expensesProvider), isEmpty);
      expect(container.read(harvestsProvider), isEmpty);
      expect(container.read(alertsProvider), isEmpty);
      expect(container.read(currentLocaleProvider), equals(const Locale('en')));
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(container.read(currentSubscriptionTierProvider), equals(SubscriptionTier.free));
    });

    test('Locale and Theme state can be updated independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentLocaleProvider.notifier).state = const Locale('te');
      expect(container.read(currentLocaleProvider).languageCode, equals('te'));

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('clearAllUserData resets all user profile and domain data to initial clean state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Populate dummy user state
      container.read(currentUserProvider.notifier).state = {
        'id': 'usr_test',
        'name': 'Test Farmer',
        'phone': '9876543210',
      };
      container.read(currentFarmProvider.notifier).state = {
        'farmId': 'farm_test',
        'farmName': 'Test Aquaculture',
      };
      container.read(pondListProvider.notifier).state = [
        {'id': 'p1', 'name': 'Pond 1'},
      ];
      container.read(expensesProvider.notifier).state = [
        Expense(
          id: 'exp_1',
          category: ExpenseCategory.feed,
          amount: 5000,
          date: DateTime.now(),
          pondId: 'p1',
          pondName: 'Pond 1',
        ),
      ];
      container.read(harvestsProvider.notifier).state = [
        HarvestRecord(
          id: 'har_1',
          date: DateTime.now(),
          pondId: 'p1',
          pondName: 'Pond 1',
          harvestType: 'Complete',
          biomassKg: 1000,
          countPerKg: 30,
          pricePerKg: 380,
          fcr: 1.2,
        ),
      ];
      container.read(currentSubscriptionTierProvider.notifier).state = SubscriptionTier.pro;

      expect(container.read(currentUserProvider), isNotNull);
      expect(container.read(currentFarmProvider), isNotNull);
      expect(container.read(pondListProvider), hasLength(1));
      expect(container.read(expensesProvider), hasLength(1));
      expect(container.read(harvestsProvider), hasLength(1));
      expect(container.read(currentSubscriptionTierProvider), equals(SubscriptionTier.pro));

      // Call clearAllUserData
      clearAllUserData(container);

      // Verify complete invalidation
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(currentFarmProvider), isNull);
      expect(container.read(pondListProvider), isEmpty);
      expect(container.read(waterLogsProvider), isEmpty);
      expect(container.read(feedLogsProvider), isEmpty);
      expect(container.read(diseaseScansProvider), isEmpty);
      expect(container.read(expensesProvider), isEmpty);
      expect(container.read(harvestsProvider), isEmpty);
      expect(container.read(alertsProvider), isEmpty);
      expect(container.read(activeFeedPlanProvider), isNull);
      expect(container.read(currentSubscriptionTierProvider), equals(SubscriptionTier.free));
    });
  });
}
