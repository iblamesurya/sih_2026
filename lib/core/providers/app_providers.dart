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
  return SubscriptionService();
});

/// Provider for [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for [WeatherService].
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
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

/// Active daily feed plan recommendation.
final activeFeedPlanProvider = StateProvider<DailyFeedPlan?>((ref) => null);

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
  ref.read(activeFeedPlanProvider.notifier).state = null;
  ref.read(currentSubscriptionTierProvider.notifier).state = SubscriptionTier.free;
}

/// Extension helper on [WidgetRef] for convenient state clearing from UI widgets.
extension WidgetRefSessionExtensions on WidgetRef {
  void clearUserData() {
    clearAllUserData(this);
  }
}
