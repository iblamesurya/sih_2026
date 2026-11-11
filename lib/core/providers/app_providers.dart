import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_client.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';
import '../services/alert_system.dart';
import '../services/feed_ai_service.dart';
import '../services/telugu_voice_nlu_service.dart';
import '../services/prawndoc_ai_service.dart';
import '../services/subscription_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/realtime_service.dart';
import '../services/farm_data_repository.dart';
import '../services/emergency_alarm_service.dart';
import '../services/data_hydration_service.dart';
import '../../features/finance/models/finance_models.dart';

// ============================================================================
// Core Services Providers
// ============================================================================

/// Provider for the active [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientService.client;
});

/// Provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for [OfflineSyncService].
final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

/// Provider for [AlertSystem].
final alertSystemProvider = Provider<AlertSystem>((ref) {
  return const AlertSystem();
});

/// Provider for [FeedAIService].
final feedAiServiceProvider = Provider<FeedAIService>((ref) {
  return const FeedAIService();
});

/// Provider for [TeluguVoiceNLUService].
final teluguVoiceNluProvider = Provider<TeluguVoiceNLUService>((ref) {
  return const TeluguVoiceNLUService();
});

/// Provider for [PrawnDocAIService].
final prawnDocAiProvider = Provider<PrawnDocAIService>((ref) {
  return const PrawnDocAIService();
});

/// Provider for [SubscriptionService].
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return const SubscriptionService();
});

/// Provider for [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for [WeatherService].
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Provider for [RealtimeService].
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});

/// Provider for [FarmDataRepository].
final farmDataRepositoryProvider = Provider<FarmDataRepository>((ref) {
  final sync = ref.watch(offlineSyncProvider);
  return FarmDataRepository(offlineSyncService: sync);
});

/// Provider for [EmergencyAlarmService].
final emergencyAlarmServiceProvider = Provider<EmergencyAlarmService>((ref) {
  return const EmergencyAlarmService();
});

/// Provider for [DataHydrationService].
final dataHydrationServiceProvider = Provider<DataHydrationService>((ref) {
  return DataHydrationService();
});

// ============================================================================
// App Session & Localization State Providers
// ============================================================================

/// Active user profile data (null when unauthenticated).
final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Currently selected or primary farm data.
final currentFarmProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Active app locale ('en' or 'te').
final currentLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Active app theme mode (defaults to dark for Deep Ocean Matte).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// User's current subscription tier.
final currentSubscriptionTierProvider =
    StateProvider<SubscriptionTier>((ref) => SubscriptionTier.free);

/// Active GPS location coordinates.
final currentLocationCoordinatesProvider =
    StateProvider<LocationCoordinates?>((ref) => null);

// ============================================================================
// Domain Entity State Providers
// ============================================================================

/// List of ponds belonging to the active farm.
final pondListProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Historical water quality telemetry logs.
final waterLogsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Historical feed logs across ponds.
final feedLogsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Disease scan diagnostic records.
final diseaseScansProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Farm expenses ledger.
final expensesProvider = StateProvider<List<Expense>>((ref) => []);

/// Farm harvest records.
final harvestsProvider = StateProvider<List<HarvestRecord>>((ref) => []);

/// Active water quality and environmental alerts.
final alertsProvider = StateProvider<List<WaterAlert>>((ref) => []);

/// Active life-safety emergency alarms (nocturnal DO crashes, toxic ammonia spikes).
final activeEmergencyAlarmsProvider =
    StateProvider<List<EmergencyAlarm>>((ref) => []);

/// Active daily feed plan recommendation.
final activeFeedPlanProvider = StateProvider<DailyFeedPlan?>((ref) => null);

/// Completed meal numbers (1..4) for today's feed schedule.
final completedMealsProvider = StateProvider<Set<int>>((ref) => <int>{});

/// Monthly exported PDF reports count for subscription quota tracking.
final exportedReportsCountProvider = StateProvider<int>((ref) => 0);

/// Pending offline mutation count in [OfflineSyncService].
final pendingSyncCountProvider = StateProvider<int>((ref) => 0);

/// Non-destructive ABW & count sampling records across ponds.
final abwSamplesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Default regional Andhra Pradesh shrimp mandi prices (₹/kg by count size).
List<Map<String, dynamic>> defaultAndhraMandiPrices() => [
      {
        'id': 'mp_bvrm_30',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '30c',
        'price_per_kg': 390.0,
        'change_24h': 10.0,
        'buyer': 'Devi Sea Foods / Export Grade A',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_40',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '40c',
        'price_per_kg': 335.0,
        'change_24h': 5.0,
        'buyer': 'Avanti Frozen Foods',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_50',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '50c',
        'price_per_kg': 295.0,
        'change_24h': 0.0,
        'buyer': 'Nekkanti Sea Foods',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_60',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '60c',
        'price_per_kg': 265.0,
        'change_24h': -5.0,
        'buyer': 'Sandhya Aqua Exports',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_70',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '70c',
        'price_per_kg': 248.0,
        'change_24h': 0.0,
        'buyer': 'Godavari Cold Storage',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_80',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '80c',
        'price_per_kg': 230.0,
        'change_24h': 0.0,
        'buyer': 'Local Packing Center',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_bvrm_100',
        'district': 'Bhimavaram (West Godavari)',
        'species': 'L. vannamei',
        'count_size': '100c',
        'price_per_kg': 205.0,
        'change_24h': -5.0,
        'buyer': 'Local Packing Center',
        'recorded_date': 'Today, 10:00 AM',
      },
      {
        'id': 'mp_nlr_30',
        'district': 'Nellore (Gudur / Kavali)',
        'species': 'L. vannamei',
        'count_size': '30c',
        'price_per_kg': 395.0,
        'change_24h': 10.0,
        'buyer': 'Apex Frozen Foods',
        'recorded_date': 'Today, 10:30 AM',
      },
      {
        'id': 'mp_nlr_40',
        'district': 'Nellore (Gudur / Kavali)',
        'species': 'L. vannamei',
        'count_size': '40c',
        'price_per_kg': 340.0,
        'change_24h': 5.0,
        'buyer': 'Ananda Group',
        'recorded_date': 'Today, 10:30 AM',
      },
      {
        'id': 'mp_kkl_30',
        'district': 'Kaikaluru (Kolleru / Eluru)',
        'species': 'L. vannamei',
        'count_size': '30c',
        'price_per_kg': 388.0,
        'change_24h': 6.0,
        'buyer': 'Kolleru Export Processors',
        'recorded_date': 'Today, 10:10 AM',
      },
      {
        'id': 'mp_kkl_50',
        'district': 'Kaikaluru (Kolleru / Eluru)',
        'species': 'L. vannamei',
        'count_size': '50c',
        'price_per_kg': 292.0,
        'change_24h': 2.0,
        'buyer': 'Eluru Fresh Marine Hub',
        'recorded_date': 'Today, 10:10 AM',
      },
      {
        'id': 'mp_kkd_30',
        'district': 'Kakinada & Amalapuram',
        'species': 'L. vannamei',
        'count_size': '30c',
        'price_per_kg': 392.0,
        'change_24h': 8.0,
        'buyer': 'Kakinada Port Exporters',
        'recorded_date': 'Today, 10:15 AM',
      },
      {
        'id': 'mp_kkd_20_monodon',
        'district': 'Kakinada & Amalapuram',
        'species': 'P. monodon',
        'count_size': '20c',
        'price_per_kg': 580.0,
        'change_24h': 15.0,
        'buyer': 'Black Tiger Export Desk',
        'recorded_date': 'Today, 10:15 AM',
      },
      {
        'id': 'mp_mtm_40',
        'district': 'Machilipatnam (Krishna)',
        'species': 'L. vannamei',
        'count_size': '40c',
        'price_per_kg': 330.0,
        'change_24h': 0.0,
        'buyer': 'Krishna Aqua Hub',
        'recorded_date': 'Today, 09:45 AM',
      },
      {
        'id': 'mp_ong_40',
        'district': 'Ongole & Bapatla',
        'species': 'L. vannamei',
        'count_size': '40c',
        'price_per_kg': 334.0,
        'change_24h': 4.0,
        'buyer': 'Prakasam Seafood Packers',
        'recorded_date': 'Today, 10:00 AM',
      },
    ];

/// Live & crowdsourced regional shrimp mandi prices.
final marketPricesProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => defaultAndhraMandiPrices(),
);

// ============================================================================
// State Invalidation & Sign-Out Cleanup
// ============================================================================

/// Clears all user session and farm domain data across Riverpod state.
///
/// Can be invoked with either a Riverpod [Ref] or [WidgetRef].
void clearAllUserData(dynamic ref) {
  ref.read(currentUserProvider.notifier).state = null;
  ref.read(currentFarmProvider.notifier).state = null;
  ref.read(pondListProvider.notifier).state = <Map<String, dynamic>>[];
  ref.read(waterLogsProvider.notifier).state = <Map<String, dynamic>>[];
  ref.read(feedLogsProvider.notifier).state = <Map<String, dynamic>>[];
  ref.read(diseaseScansProvider.notifier).state = <Map<String, dynamic>>[];
  ref.read(expensesProvider.notifier).state = <Expense>[];
  ref.read(harvestsProvider.notifier).state = <HarvestRecord>[];
  ref.read(alertsProvider.notifier).state = <WaterAlert>[];
  ref.read(activeEmergencyAlarmsProvider.notifier).state = <EmergencyAlarm>[];
  ref.read(activeFeedPlanProvider.notifier).state = null;
  ref.read(completedMealsProvider.notifier).state = <int>{};
  ref.read(exportedReportsCountProvider.notifier).state = 0;
  ref.read(pendingSyncCountProvider.notifier).state = 0;
  ref.read(abwSamplesProvider.notifier).state = <Map<String, dynamic>>[];
  ref.read(marketPricesProvider.notifier).state = defaultAndhraMandiPrices();
  ref.read(currentSubscriptionTierProvider.notifier).state = SubscriptionTier.free;
  ref.read(currentLocationCoordinatesProvider.notifier).state = null;
  try {
    final hydration = ref.read(dataHydrationServiceProvider) as DataHydrationService;
    hydration.clearLocalSnapshot();
  } catch (_) {}
}

/// Extension helper on [WidgetRef] for convenient state clearing from UI widgets.
extension WidgetRefSessionExtensions on WidgetRef {
  void clearUserData() {
    clearAllUserData(this);
  }
}
