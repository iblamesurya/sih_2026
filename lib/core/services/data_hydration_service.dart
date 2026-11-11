import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/finance/models/finance_models.dart';
import '../providers/app_providers.dart';
import 'alert_system.dart';
import 'emergency_alarm_service.dart';
import 'farm_data_repository.dart';
import 'offline_sync_service.dart';
import 'realtime_service.dart';
import 'subscription_service.dart';

/// Orchestrates local snapshot persistence (`SharedPreferences`), remote Supabase
/// hydration (`FarmDataRepository`), automatic offline queue draining, and live
/// `RealtimeService` stream synchronization into Riverpod state.
class DataHydrationService {
  static const String keyUser = 'pg_snapshot_user';
  static const String keyFarm = 'pg_snapshot_farm';
  static const String keyPonds = 'pg_snapshot_ponds';
  static const String keyWaterLogs = 'pg_snapshot_water_logs';
  static const String keyFeedLogs = 'pg_snapshot_feed_logs';
  static const String keyDiseaseScans = 'pg_snapshot_disease_scans';
  static const String keyExpenses = 'pg_snapshot_expenses';
  static const String keyHarvests = 'pg_snapshot_harvests';
  static const String keyMarketPrices = 'pg_snapshot_market_prices';
  static const String keyAbwSamples = 'pg_snapshot_abw_samples';
  static const String keyLocale = 'pg_snapshot_locale';
  static const String keySubscriptionTier = 'pg_snapshot_subscription_tier';
  static const String keyCompletedMeals = 'pg_snapshot_completed_meals';
  static const String keyExportedReports = 'pg_snapshot_exported_reports';

  final List<StreamSubscription<dynamic>> _realtimeSubscriptions = [];

  DataHydrationService();

  /// Saves the current Riverpod state snapshot to `SharedPreferences` so all
  /// farm data survives app restarts even when 100% offline.
  Future<void> saveSnapshotToLocal(dynamic ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final user = ref.read(currentUserProvider) as Map<String, dynamic>?;
      if (user != null) {
        await prefs.setString(keyUser, jsonEncode(user));
      } else {
        await prefs.remove(keyUser);
      }

      final farm = ref.read(currentFarmProvider) as Map<String, dynamic>?;
      if (farm != null) {
        await prefs.setString(keyFarm, jsonEncode(farm));
      } else {
        await prefs.remove(keyFarm);
      }

      final ponds = ref.read(pondListProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyPonds, jsonEncode(ponds));

      final waterLogs =
          ref.read(waterLogsProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyWaterLogs, jsonEncode(waterLogs));

      final feedLogs = ref.read(feedLogsProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyFeedLogs, jsonEncode(feedLogs));

      final scans =
          ref.read(diseaseScansProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyDiseaseScans, jsonEncode(scans));

      final expenses = ref.read(expensesProvider) as List<Expense>;
      await prefs.setString(
        keyExpenses,
        jsonEncode(expenses.map((e) => e.toJson()).toList()),
      );

      final harvests = ref.read(harvestsProvider) as List<HarvestRecord>;
      await prefs.setString(
        keyHarvests,
        jsonEncode(harvests.map((h) => h.toJson()).toList()),
      );

      final marketPrices =
          ref.read(marketPricesProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyMarketPrices, jsonEncode(marketPrices));

      final abwSamples =
          ref.read(abwSamplesProvider) as List<Map<String, dynamic>>;
      await prefs.setString(keyAbwSamples, jsonEncode(abwSamples));

      final locale = ref.read(currentLocaleProvider) as Locale;
      await prefs.setString(keyLocale, locale.languageCode);

      final tier = ref.read(currentSubscriptionTierProvider) as SubscriptionTier;
      await prefs.setString(keySubscriptionTier, tier.name);

      final meals = ref.read(completedMealsProvider) as Set<int>;
      await prefs.setString(keyCompletedMeals, jsonEncode(meals.toList()));

      final exportedCount = ref.read(exportedReportsCountProvider) as int;
      await prefs.setInt(keyExportedReports, exportedCount);
    } catch (e) {
      debugPrint('DataHydrationService.saveSnapshotToLocal notice: $e');
    }
  }

  /// Restores persisted domain state from `SharedPreferences` into Riverpod providers.
  Future<bool> restoreFromLocalSnapshot(dynamic ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var restoredAny = false;

      final userRaw = prefs.getString(keyUser);
      if (userRaw != null && userRaw.isNotEmpty) {
        ref.read(currentUserProvider.notifier).state =
            Map<String, dynamic>.from(jsonDecode(userRaw) as Map);
        restoredAny = true;
      }

      final farmRaw = prefs.getString(keyFarm);
      if (farmRaw != null && farmRaw.isNotEmpty) {
        ref.read(currentFarmProvider.notifier).state =
            Map<String, dynamic>.from(jsonDecode(farmRaw) as Map);
        restoredAny = true;
      }

      final pondsRaw = prefs.getString(keyPonds);
      if (pondsRaw != null && pondsRaw.isNotEmpty) {
        final decoded = (jsonDecode(pondsRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(pondListProvider.notifier).state = decoded;
          restoredAny = true;
        }
      }

      final waterRaw = prefs.getString(keyWaterLogs);
      if (waterRaw != null && waterRaw.isNotEmpty) {
        final decoded = (jsonDecode(waterRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(waterLogsProvider.notifier).state = decoded;
          _recomputeAlertsAndAlarms(ref, decoded, triggerSound: false);
          restoredAny = true;
        }
      }

      final feedRaw = prefs.getString(keyFeedLogs);
      if (feedRaw != null && feedRaw.isNotEmpty) {
        final decoded = (jsonDecode(feedRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(feedLogsProvider.notifier).state = decoded;
          restoredAny = true;
        }
      }

      final scansRaw = prefs.getString(keyDiseaseScans);
      if (scansRaw != null && scansRaw.isNotEmpty) {
        final decoded = (jsonDecode(scansRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(diseaseScansProvider.notifier).state = decoded;
          restoredAny = true;
        }
      }

      final expensesRaw = prefs.getString(keyExpenses);
      if (expensesRaw != null && expensesRaw.isNotEmpty) {
        final decoded = (jsonDecode(expensesRaw) as List)
            .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(expensesProvider.notifier).state = decoded;
          restoredAny = true;
        }
      }

      final harvestsRaw = prefs.getString(keyHarvests);
      if (harvestsRaw != null && harvestsRaw.isNotEmpty) {
        final decoded = (jsonDecode(harvestsRaw) as List)
            .map(
              (e) =>
                  HarvestRecord.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(harvestsProvider.notifier).state = decoded;
          restoredAny = true;
        }
      }

      final marketRaw = prefs.getString(keyMarketPrices);
      if (marketRaw != null && marketRaw.isNotEmpty) {
        final decoded = (jsonDecode(marketRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(marketPricesProvider.notifier).state = decoded;
        }
      }

      final abwRaw = prefs.getString(keyAbwSamples);
      if (abwRaw != null && abwRaw.isNotEmpty) {
        final decoded = (jsonDecode(abwRaw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (decoded.isNotEmpty) {
          ref.read(abwSamplesProvider.notifier).state = decoded;
        }
      }

      final localeCode = prefs.getString(keyLocale);
      if (localeCode == 'te' || localeCode == 'en') {
        ref.read(currentLocaleProvider.notifier).state = Locale(localeCode!);
      }

      final tierName = prefs.getString(keySubscriptionTier);
      if (tierName == SubscriptionTier.pro.name) {
        ref.read(currentSubscriptionTierProvider.notifier).state =
            SubscriptionTier.pro;
      }

      final mealsRaw = prefs.getString(keyCompletedMeals);
      if (mealsRaw != null && mealsRaw.isNotEmpty) {
        final decoded = (jsonDecode(mealsRaw) as List)
            .map((e) => (e as num).toInt())
            .toSet();
        ref.read(completedMealsProvider.notifier).state = decoded;
      }

      final exportedCount = prefs.getInt(keyExportedReports);
      if (exportedCount != null) {
        ref.read(exportedReportsCountProvider.notifier).state = exportedCount;
      }

      await refreshPendingSyncCount(ref);
      return restoredAny;
    } catch (e) {
      debugPrint('DataHydrationService.restoreFromLocalSnapshot notice: $e');
      return false;
    }
  }

  /// Flushes pending outbox mutations before remote state hydration to prevent
  /// stale remote database state from clobbering uncommitted local mutations.
  Future<int> flushPendingOutbox(
    dynamic ref, {
    OfflineSyncService? offlineSync,
  }) async {
    final syncService =
        offlineSync ?? ref.read(offlineSyncProvider) as OfflineSyncService;
    int drained = 0;
    try {
      drained = await syncService.drainQueue();
    } catch (e) {
      debugPrint('DataHydrationService.flushPendingOutbox notice: $e');
    }
    await refreshPendingSyncCount(ref, offlineSync: syncService);
    return drained;
  }

  /// Hydrates state from both local `SharedPreferences` and remote Supabase tables,
  /// strictly enforcing flush-before-hydrate ordering to prevent overwriting unsynced mutations,
  /// and merges remote records with local precedence.
  Future<void> hydrateAll(
    dynamic ref, {
    FarmDataRepository? repository,
    OfflineSyncService? offlineSync,
  }) async {
    // 1. Instant local render from device snapshot (0ms latency)
    await restoreFromLocalSnapshot(ref);

    // 2. ENFORCE FLUSH-BEFORE-HYDRATE: Drain pending outbox mutations before remote queries
    final syncService =
        offlineSync ?? ref.read(offlineSyncProvider) as OfflineSyncService;
    await flushPendingOutbox(ref, offlineSync: syncService);

    final repo =
        repository ?? ref.read(farmDataRepositoryProvider) as FarmDataRepository;
    final farm = ref.read(currentFarmProvider) as Map<String, dynamic>?;
    final farmId = farm?['id']?.toString();

    try {
      final remotePonds = await repo.fetchPonds(farmId: farmId);
      if (remotePonds.isNotEmpty) {
        final localPonds =
            ref.read(pondListProvider) as List<Map<String, dynamic>>;
        ref.read(pondListProvider.notifier).state =
            _mergeMapsById(remotePonds, localPonds);
      }

      final remoteWaterLogs = await repo.fetchWaterLogs();
      if (remoteWaterLogs.isNotEmpty) {
        final localWaterLogs =
            ref.read(waterLogsProvider) as List<Map<String, dynamic>>;
        final mergedWater = _mergeMapsById(remoteWaterLogs, localWaterLogs);
        ref.read(waterLogsProvider.notifier).state = mergedWater;
        _recomputeAlertsAndAlarms(ref, mergedWater, triggerSound: false);
      }

      final remoteFeedLogs = await repo.fetchFeedLogs();
      if (remoteFeedLogs.isNotEmpty) {
        final localFeedLogs =
            ref.read(feedLogsProvider) as List<Map<String, dynamic>>;
        ref.read(feedLogsProvider.notifier).state =
            _mergeMapsById(remoteFeedLogs, localFeedLogs);
      }

      final remoteScans = await repo.fetchDiseaseScans();
      if (remoteScans.isNotEmpty) {
        final localScans =
            ref.read(diseaseScansProvider) as List<Map<String, dynamic>>;
        ref.read(diseaseScansProvider.notifier).state =
            _mergeMapsById(remoteScans, localScans);
      }

      final remoteExpenses = await repo.fetchExpenses(farmId: farmId);
      if (remoteExpenses.isNotEmpty) {
        final localExpenses = ref.read(expensesProvider) as List<Expense>;
        final seenIds = <String>{};
        final merged = <Expense>[];
        for (final exp in [...localExpenses, ...remoteExpenses]) {
          if (seenIds.add(exp.id)) {
            merged.add(exp);
          }
        }
        ref.read(expensesProvider.notifier).state = merged;
      }

      final remoteHarvests = await repo.fetchHarvests(farmId: farmId);
      if (remoteHarvests.isNotEmpty) {
        final localHarvests = ref.read(harvestsProvider) as List<HarvestRecord>;
        final seenIds = <String>{};
        final merged = <HarvestRecord>[];
        for (final harv in [...localHarvests, ...remoteHarvests]) {
          if (seenIds.add(harv.id)) {
            merged.add(harv);
          }
        }
        ref.read(harvestsProvider.notifier).state = merged;
      }

      final remotePrices = await repo.fetchMarketPrices();
      if (remotePrices.isNotEmpty) {
        final localPrices =
            ref.read(marketPricesProvider) as List<Map<String, dynamic>>;
        ref.read(marketPricesProvider.notifier).state =
            _mergeMapsById(remotePrices, localPrices);
      }

      final remoteAbw = await repo.fetchAbwSamples();
      if (remoteAbw.isNotEmpty) {
        final localAbw =
            ref.read(abwSamplesProvider) as List<Map<String, dynamic>>;
        ref.read(abwSamplesProvider.notifier).state =
            _mergeMapsById(remoteAbw, localAbw);
      }

      await saveSnapshotToLocal(ref);
    } catch (e) {
      debugPrint('DataHydrationService.hydrateAll remote notice: $e');
    }
  }

  /// Connects [RealtimeService] broadcast streams directly to Riverpod domain providers
  /// and evaluates [AlertSystem] + [EmergencyAlarmService] on live incoming water logs.
  void bindRealtimeStreams(
    dynamic ref, {
    RealtimeService? realtimeService,
  }) {
    disposeRealtimeStreams();
    final rt = realtimeService ?? ref.read(realtimeServiceProvider) as RealtimeService;
    rt.initializeSubscriptions();

    _realtimeSubscriptions.add(
      rt.waterLogsStream.listen((newLog) {
        if (newLog.isEmpty) return;
        final current = List<Map<String, dynamic>>.from(
          ref.read(waterLogsProvider) as List<Map<String, dynamic>>,
        );
        final id = newLog['id']?.toString();
        if (id != null && id.isNotEmpty) {
          current.removeWhere((item) => item['id']?.toString() == id);
        }
        current.insert(0, newLog);
        ref.read(waterLogsProvider.notifier).state = current;
        _recomputeAlertsAndAlarms(ref, current, triggerSound: true);
        saveSnapshotToLocal(ref);
      }),
    );

    _realtimeSubscriptions.add(
      rt.feedLogsStream.listen((newLog) {
        if (newLog.isEmpty) return;
        final current = List<Map<String, dynamic>>.from(
          ref.read(feedLogsProvider) as List<Map<String, dynamic>>,
        );
        final id = newLog['id']?.toString();
        if (id != null && id.isNotEmpty) {
          current.removeWhere((item) => item['id']?.toString() == id);
        }
        current.insert(0, newLog);
        ref.read(feedLogsProvider.notifier).state = current;
        saveSnapshotToLocal(ref);
      }),
    );

    _realtimeSubscriptions.add(
      rt.diseaseScansStream.listen((newScan) {
        if (newScan.isEmpty) return;
        final current = List<Map<String, dynamic>>.from(
          ref.read(diseaseScansProvider) as List<Map<String, dynamic>>,
        );
        final id = newScan['id']?.toString();
        if (id != null && id.isNotEmpty) {
          current.removeWhere((item) => item['id']?.toString() == id);
        }
        current.insert(0, newScan);
        ref.read(diseaseScansProvider.notifier).state = current;
        saveSnapshotToLocal(ref);
      }),
    );
  }

  /// Updates [pendingSyncCountProvider] with the current [OfflineSyncService] queue size.
  Future<int> refreshPendingSyncCount(
    dynamic ref, {
    OfflineSyncService? offlineSync,
  }) async {
    try {
      final sync = offlineSync ?? ref.read(offlineSyncProvider) as OfflineSyncService;
      final queue = await sync.getQueue();
      ref.read(pendingSyncCountProvider.notifier).state = queue.length;
      return queue.length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears all saved local snapshots from `SharedPreferences` upon user sign-out.
  Future<void> clearLocalSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyUser);
      await prefs.remove(keyFarm);
      await prefs.remove(keyPonds);
      await prefs.remove(keyWaterLogs);
      await prefs.remove(keyFeedLogs);
      await prefs.remove(keyDiseaseScans);
      await prefs.remove(keyExpenses);
      await prefs.remove(keyHarvests);
      await prefs.remove(keyMarketPrices);
      await prefs.remove(keyAbwSamples);
      await prefs.remove(keySubscriptionTier);
      await prefs.remove(keyCompletedMeals);
      await prefs.remove(keyExportedReports);
    } catch (_) {}
  }

  void _recomputeAlertsAndAlarms(
    dynamic ref,
    List<Map<String, dynamic>> waterLogs, {
    required bool triggerSound,
  }) {
    if (waterLogs.isEmpty) return;
    final alertSystem = ref.read(alertSystemProvider) as AlertSystem;
    final alarmService =
        ref.read(emergencyAlarmServiceProvider) as EmergencyAlarmService;

    // Evaluate the most recent reading per pond
    final latestByPond = <String, Map<String, dynamic>>{};
    for (final log in waterLogs) {
      final pondId = (log['pondId'] ?? log['pond_id'] ?? 'p1').toString();
      latestByPond.putIfAbsent(pondId, () => log);
    }

    final computedAlerts = <WaterAlert>[];
    final computedAlarms = <EmergencyAlarm>[];

    for (final log in latestByPond.values) {
      final ph = (log['ph'] as num?)?.toDouble();
      final doVal =
          ((log['dissolvedOxygen'] ?? log['dissolved_oxygen'] ?? log['do'])
                  as num?)
              ?.toDouble();
      final ammonia = ((log['ammonia'] ?? log['tan']) as num?)?.toDouble();
      final salinity = (log['salinity'] as num?)?.toDouble();
      final temperature =
          ((log['temperature'] ?? log['temp']) as num?)?.toDouble();

      computedAlerts.addAll(
        alertSystem.evaluateParameters(
          ph: ph,
          dissolvedOxygen: doVal,
          ammonia: ammonia,
          salinity: salinity,
          temperature: temperature,
        ),
      );

      computedAlarms.addAll(
        alarmService.evaluateWaterLog(
          log,
          triggerSoundAndHaptics: triggerSound,
        ),
      );
    }

    if (computedAlerts.isNotEmpty) {
      ref.read(alertsProvider.notifier).state = computedAlerts;
    }
    if (computedAlarms.isNotEmpty) {
      ref.read(activeEmergencyAlarmsProvider.notifier).state = computedAlarms;
    }
  }

  List<Map<String, dynamic>> _mergeMapsById(
    List<Map<String, dynamic>> remote,
    List<Map<String, dynamic>> local,
  ) {
    final seenIds = <String>{};
    final merged = <Map<String, dynamic>>[];

    for (final item in [...local, ...remote]) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) {
        merged.add(item);
      } else if (seenIds.add(id)) {
        merged.add(item);
      }
    }
    return merged;
  }

  void disposeRealtimeStreams() {
    for (final sub in _realtimeSubscriptions) {
      sub.cancel();
    }
    _realtimeSubscriptions.clear();
  }
}
