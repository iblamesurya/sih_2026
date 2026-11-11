import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/finance/models/finance_models.dart';
import 'base_repository.dart';
import 'offline_sync_service.dart';
import 'supabase_client.dart';

/// Concrete repository extending [BaseRepository] that provides bidirectional
/// Supabase `.select()` reads (with TTL caching and offline safety) and
/// `.insert()` / `.upsert()` mutations (with automatic [OfflineSyncService] queuing).
class FarmDataRepository extends BaseRepository {
  final SupabaseClient? _injectedClient;

  FarmDataRepository({
    SupabaseClient? client,
    OfflineSyncService? offlineSyncService,
  })  : _injectedClient = client,
        super(offlineSyncService);

  SupabaseClient get _client => _injectedClient ?? SupabaseClientService.client;

  // ===========================================================================
  // READS (.select() queries with TTL cache + graceful offline fallback)
  // ===========================================================================

  /// Fetches the user's profile from `profiles` table.
  Future<Map<String, dynamic>?> fetchUserProfile(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<Map<String, dynamic>?>(
        key: 'profile_$userId',
        ttl: const Duration(minutes: 10),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final response = await _client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          return response;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchUserProfile fallback ($e)');
      }
      return null;
    }
  }

  /// Fetches the primary farm record for [userId] from `farms` table.
  Future<Map<String, dynamic>?> fetchPrimaryFarm(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<Map<String, dynamic>?>(
        key: 'farm_$userId',
        ttl: const Duration(minutes: 10),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final response = await _client
              .from('farms')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          return response;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchPrimaryFarm fallback ($e)');
      }
      return null;
    }
  }

  /// Fetches ponds from `ponds` table.
  Future<List<Map<String, dynamic>>> fetchPonds({
    String? farmId,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'ponds_${farmId ?? "all"}',
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('ponds').select();
          final response = farmId != null && farmId.isNotEmpty
              ? await query
                  .eq('farm_id', farmId)
                  .order('created_at', ascending: true)
              : await query.order('created_at', ascending: true);
          return List<Map<String, dynamic>>.from(response);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchPonds fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches water quality telemetry logs from `water_logs` table.
  Future<List<Map<String, dynamic>>> fetchWaterLogs({
    String? pondId,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'water_logs_${pondId ?? "all"}_$limit',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('water_logs').select();
          final response = pondId != null && pondId.isNotEmpty
              ? await query
                  .eq('pond_id', pondId)
                  .order('logged_at', ascending: false)
                  .limit(limit)
              : await query.order('logged_at', ascending: false).limit(limit);
          return List<Map<String, dynamic>>.from(response);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchWaterLogs fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches feed logs from `feed_logs` table.
  Future<List<Map<String, dynamic>>> fetchFeedLogs({
    String? pondId,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'feed_logs_${pondId ?? "all"}_$limit',
        ttl: const Duration(minutes: 2),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('feed_logs').select();
          final response = pondId != null && pondId.isNotEmpty
              ? await query
                  .eq('pond_id', pondId)
                  .order('fed_at', ascending: false)
                  .limit(limit)
              : await query.order('fed_at', ascending: false).limit(limit);
          return List<Map<String, dynamic>>.from(response);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchFeedLogs fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches disease scan records from `disease_scans` table.
  Future<List<Map<String, dynamic>>> fetchDiseaseScans({
    String? pondId,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'disease_scans_${pondId ?? "all"}_$limit',
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('disease_scans').select();
          final response = pondId != null && pondId.isNotEmpty
              ? await query
                  .eq('pond_id', pondId)
                  .order('scanned_at', ascending: false)
                  .limit(limit)
              : await query.order('scanned_at', ascending: false).limit(limit);
          return List<Map<String, dynamic>>.from(response);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchDiseaseScans fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches farm expenses from `expenses` table and maps them to [Expense].
  Future<List<Expense>> fetchExpenses({
    String? farmId,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Expense>>(
        key: 'expenses_${farmId ?? "all"}',
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('expenses').select();
          final rows = farmId != null && farmId.isNotEmpty
              ? await query
                  .eq('farm_id', farmId)
                  .order('incurred_at', ascending: false)
              : await query.order('incurred_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows)
              .map(Expense.fromJson)
              .toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchExpenses fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches harvest records from `harvests` table and maps them to [HarvestRecord].
  Future<List<HarvestRecord>> fetchHarvests({
    String? farmId,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<HarvestRecord>>(
        key: 'harvests_${farmId ?? "all"}',
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('harvests').select();
          final rows = farmId != null && farmId.isNotEmpty
              ? await query
                  .eq('farm_id', farmId)
                  .order('harvested_at', ascending: false)
              : await query.order('harvested_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows)
              .map(HarvestRecord.fromJson)
              .toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchHarvests fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches live shrimp mandi prices from `market_prices` table.
  Future<List<Map<String, dynamic>>> fetchMarketPrices({
    String? district,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'market_prices_${district ?? "all"}',
        ttl: const Duration(minutes: 15),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('market_prices').select();
          final rows = district != null && district.isNotEmpty
              ? await query
                  .eq('district', district)
                  .order('recorded_date', ascending: false)
              : await query.order('recorded_date', ascending: false).limit(50);
          return List<Map<String, dynamic>>.from(rows);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchMarketPrices fallback ($e)');
      }
      return const [];
    }
  }

  /// Fetches ABW growth sampling records from `abw_samples` table.
  Future<List<Map<String, dynamic>>> fetchAbwSamples({
    String? pondId,
    bool forceRefresh = false,
  }) async {
    try {
      return await getOrFetch<List<Map<String, dynamic>>>(
        key: 'abw_samples_${pondId ?? "all"}',
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
        fetcher: () async {
          final query = _client.from('abw_samples').select();
          final rows = pondId != null && pondId.isNotEmpty
              ? await query
                  .eq('pond_id', pondId)
                  .order('sampled_at', ascending: false)
              : await query.order('sampled_at', ascending: false).limit(50);
          return List<Map<String, dynamic>>.from(rows);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FarmDataRepository.fetchAbwSamples fallback ($e)');
      }
      return const [];
    }
  }

  // ===========================================================================
  // WRITES (safeMutate with automatic OfflineSyncService fallback)
  // ===========================================================================

  /// Persists a pond to Supabase or queues it in [OfflineSyncService] on network error.
  Future<Map<String, dynamic>?> savePond(Map<String, dynamic> pond) {
    BaseRepository.invalidateCache('ponds_');
    return safeMutate<Map<String, dynamic>>(
      networkAction: () async {
        await _client.from('ponds').upsert(pond);
        return pond;
      },
      offlineMutation: {
        'table': 'ponds',
        'action': 'upsert',
        'payload': pond,
      },
      fallbackValue: pond,
    );
  }

  /// Persists a water log to Supabase or queues it offline.
  Future<Map<String, dynamic>?> saveWaterLog(Map<String, dynamic> log) {
    BaseRepository.invalidateCache('water_logs_');
    return safeMutate<Map<String, dynamic>>(
      networkAction: () async {
        await _client.from('water_logs').insert(log);
        return log;
      },
      offlineMutation: {
        'table': 'water_logs',
        'action': 'insert',
        'payload': log,
      },
      fallbackValue: log,
    );
  }

  /// Persists a feed log to Supabase or queues it offline.
  Future<Map<String, dynamic>?> saveFeedLog(Map<String, dynamic> log) {
    BaseRepository.invalidateCache('feed_logs_');
    return safeMutate<Map<String, dynamic>>(
      networkAction: () async {
        await _client.from('feed_logs').insert(log);
        return log;
      },
      offlineMutation: {
        'table': 'feed_logs',
        'action': 'insert',
        'payload': log,
      },
      fallbackValue: log,
    );
  }

  /// Persists a market price quote to Supabase or queues it offline.
  Future<Map<String, dynamic>?> saveMarketPrice(Map<String, dynamic> price) {
    BaseRepository.invalidateCache('market_prices_');
    return safeMutate<Map<String, dynamic>>(
      networkAction: () async {
        await _client.from('market_prices').insert(price);
        return price;
      },
      offlineMutation: {
        'table': 'market_prices',
        'action': 'insert',
        'payload': price,
      },
      fallbackValue: price,
    );
  }

  /// Persists an ABW sample to Supabase or queues it offline.
  Future<Map<String, dynamic>?> saveAbwSample(Map<String, dynamic> sample) {
    BaseRepository.invalidateCache('abw_samples_');
    return safeMutate<Map<String, dynamic>>(
      networkAction: () async {
        await _client.from('abw_samples').insert(sample);
        return sample;
      },
      offlineMutation: {
        'table': 'abw_samples',
        'action': 'insert',
        'payload': sample,
      },
      fallbackValue: sample,
    );
  }
}
