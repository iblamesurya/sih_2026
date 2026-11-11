import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prawn_guard/core/providers/app_providers.dart';
import 'package:prawn_guard/core/router/app_router.dart';
import 'package:prawn_guard/core/services/emergency_alarm_service.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';
import 'package:prawn_guard/features/finance/models/finance_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataHydrationService, Realtime Wiring & EmergencyAlarmService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Persists domain state to SharedPreferences and restores across container restarts', () async {
      final container1 = ProviderContainer();
      addTearDown(container1.dispose);

      container1.read(currentUserProvider.notifier).state = {
        'id': 'usr_101',
        'name': 'Ramesh Raju',
        'phone': '9876543210',
      };
      container1.read(pondListProvider.notifier).state = [
        {'id': 'p_1', 'name': 'Bhimavaram Pond 1', 'areaHa': 1.5, 'doc': 52, 'abw': 19.2},
      ];
      container1.read(waterLogsProvider.notifier).state = [
        {'id': 'w_1', 'pond_id': 'p_1', 'ph': 7.9, 'dissolved_oxygen': 5.4, 'ammonia': 0.02},
      ];
      container1.read(expensesProvider.notifier).state = [
        Expense(
          id: 'exp_1',
          category: ExpenseCategory.feed,
          amount: 42000,
          date: DateTime(2026, 10, 15),
          pondId: 'p_1',
          pondName: 'Bhimavaram Pond 1',
        ),
      ];
      container1.read(currentLocaleProvider.notifier).state = const Locale('te');
      container1.read(currentSubscriptionTierProvider.notifier).state = SubscriptionTier.pro;

      final hydration1 = container1.read(dataHydrationServiceProvider);
      await hydration1.saveSnapshotToLocal(container1);

      // Simulate app restart with a brand new ProviderContainer
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      expect(container2.read(pondListProvider), isEmpty);

      final hydration2 = container2.read(dataHydrationServiceProvider);
      final restored = await hydration2.restoreFromLocalSnapshot(container2);

      expect(restored, isTrue);
      expect(container2.read(currentUserProvider)?['name'], equals('Ramesh Raju'));
      expect(container2.read(pondListProvider).length, equals(1));
      expect(container2.read(pondListProvider).first['name'], equals('Bhimavaram Pond 1'));
      expect(container2.read(waterLogsProvider).length, equals(1));
      expect(container2.read(expensesProvider).length, equals(1));
      expect(container2.read(expensesProvider).first.amount, equals(42000));
      expect(container2.read(currentLocaleProvider).languageCode, equals('te'));
      expect(container2.read(currentSubscriptionTierProvider), equals(SubscriptionTier.pro));
    });

    test('RealtimeService water log emission updates waterLogsProvider and triggers EmergencyAlarmService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final hydration = container.read(dataHydrationServiceProvider);
      final realtime = container.read(realtimeServiceProvider);
      hydration.bindRealtimeStreams(container, realtimeService: realtime);

      realtime.emitWaterLog({
        'id': 'rt_log_1',
        'pond_id': 'pond_2',
        'pond_name': 'Pond 2',
        'ph': 6.7,
        'dissolved_oxygen': 2.3,
        'ammonia': 0.15,
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final logs = container.read(waterLogsProvider);
      expect(logs.length, equals(1));
      expect(logs.first['id'], equals('rt_log_1'));

      final alarms = container.read(activeEmergencyAlarmsProvider);
      expect(alarms.length, greaterThanOrEqualTo(2));
      expect(
        alarms.any((a) => a.parameter == 'Dissolved Oxygen'),
        isTrue,
      );
      expect(
        alarms.any((a) => a.parameter == 'Ammonia (TAN)'),
        isTrue,
      );
    });

    test('EmergencyAlarmService evaluates nocturnal hypoxia forecast accurately', () {
      const service = EmergencyAlarmService();

      final lowRisk = service.evaluateHypoxiaForecast(
        riskScore: 40,
        locationName: 'Nellore',
        triggerSoundAndHaptics: false,
      );
      expect(lowRisk, isNull);

      final highRisk = service.evaluateHypoxiaForecast(
        riskScore: 85,
        locationName: 'Bhimavaram',
        triggerSoundAndHaptics: false,
      );
      expect(highRisk, isNotNull);
      expect(highRisk!.parameter, equals('Nocturnal Hypoxia Risk'));
      expect(highRisk.checklist, isNotEmpty);
      expect(highRisk.teluguChecklist, isNotEmpty);
    });

    testWidgets('Renders MandiPricesPage (/market-prices) and AbwCameraSamplingPage (/abw-sampling)', (tester) async {
      final marketRouter = createPrawnGuardRouter(initialLocation: '/market-prices');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: marketRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live AP Shrimp Mandi Rates'), findsOneWidget);
      expect(find.textContaining('Harvest Timing Optimizer'), findsOneWidget);

      final abwRouter = createPrawnGuardRouter(initialLocation: '/abw-sampling');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: abwRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Camera ABW & Count Sizing'), findsOneWidget);
      expect(find.textContaining('Save Sample & Update Pond ABW'), findsOneWidget);
    });
  });
}
