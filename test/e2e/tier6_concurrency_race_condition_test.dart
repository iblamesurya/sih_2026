import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/weather_service.dart';
import 'package:prawn_guard/core/services/base_repository.dart';

class _TestRepository extends BaseRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 6 — Concurrency, Race Condition & Middleware Caching Hardening', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      WeatherService.clearCache();
      BaseRepository.invalidateCache();
    });

    test('6.1 Rapid concurrent enqueues are serialized without data loss or corruption', () async {
      final syncService = OfflineSyncService();
      await syncService.clearQueue();

      // Dispatch 40 concurrent enqueues simultaneously
      final futures = <Future<void>>[];
      for (int i = 0; i < 40; i++) {
        futures.add(syncService.enqueue({
          'table': 'water_logs',
          'action': 'INSERT',
          'index': i,
        }));
      }

      await Future.wait(futures);

      final queue = await syncService.getQueue();
      expect(queue.length, equals(40));

      // Verify all items are present
      final indices = queue.map((e) => e['index'] as int).toSet();
      expect(indices.length, equals(40));
    });

    test('6.2 Concurrent drainQueue calls are mutex-protected against race condition duplication', () async {
      final syncService = OfflineSyncService();
      await syncService.clearQueue();

      for (int i = 0; i < 15; i++) {
        await syncService.enqueue({
          'table': 'feed_logs',
          'action': 'INSERT',
          'index': i,
        });
      }

      expect(await syncService.queueLength, equals(15));

      final processedIndices = <int>[];

      // Slow executor simulating network latency
      Future<bool> slowExecutor(Map<String, dynamic> mutation) async {
        await Future.delayed(const Duration(milliseconds: 25));
        processedIndices.add(mutation['index'] as int);
        return true;
      }

      // Trigger two concurrent drain calls at the exact same moment
      final drain1 = syncService.drainQueue(executor: slowExecutor);
      final drain2 = syncService.drainQueue(executor: slowExecutor);

      final results = await Future.wait([drain1, drain2]);

      // At least one drain returns the processed count, and second drain awaits the active drain
      expect(results[0], equals(15));
      expect(results[1], equals(15));

      // Crucial: exactly 15 mutations executed, NO duplicate executions!
      expect(processedIndices.length, equals(15));
      expect(await syncService.queueLength, equals(0));
    });

    test('6.3 BaseRepository getOrFetch caches data within TTL and refreshes on expiry', () async {
      final repo = _TestRepository();
      int networkCallCount = 0;

      Future<String> fetchPonds() async {
        networkCallCount++;
        return 'ponds_data_v$networkCallCount';
      }

      // First fetch: network called
      final result1 = await repo.getOrFetch<String>(
        key: 'farm_ponds_1',
        ttl: const Duration(milliseconds: 100),
        fetcher: fetchPonds,
      );
      expect(result1, equals('ponds_data_v1'));
      expect(networkCallCount, equals(1));

      // Second fetch immediately: served from cache without network call
      final result2 = await repo.getOrFetch<String>(
        key: 'farm_ponds_1',
        ttl: const Duration(milliseconds: 100),
        fetcher: fetchPonds,
      );
      expect(result2, equals('ponds_data_v1'));
      expect(networkCallCount, equals(1));

      // Force refresh bypasses cache
      final result3 = await repo.getOrFetch<String>(
        key: 'farm_ponds_1',
        ttl: const Duration(milliseconds: 100),
        fetcher: fetchPonds,
        forceRefresh: true,
      );
      expect(result3, equals('ponds_data_v2'));
      expect(networkCallCount, equals(2));

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 120));

      final result4 = await repo.getOrFetch<String>(
        key: 'farm_ponds_1',
        ttl: const Duration(milliseconds: 100),
        fetcher: fetchPonds,
      );
      expect(result4, equals('ponds_data_v3'));
      expect(networkCallCount, equals(3));
    });

    test('6.4 BaseRepository cache invalidation by key and prefix works cleanly', () async {
      final repo = _TestRepository();
      int callA = 0;
      int callB = 0;

      await repo.getOrFetch<int>(key: 'ponds:p1', ttl: const Duration(minutes: 5), fetcher: () async => ++callA);
      await repo.getOrFetch<int>(key: 'ponds:p2', ttl: const Duration(minutes: 5), fetcher: () async => ++callA);
      await repo.getOrFetch<int>(key: 'weather:bhimavaram', ttl: const Duration(minutes: 5), fetcher: () async => ++callB);

      expect(callA, equals(2));
      expect(callB, equals(1));

      // Invalidate prefix 'ponds:'
      BaseRepository.invalidateCache('ponds:');

      // Fetching p1 again triggers fetcher
      await repo.getOrFetch<int>(key: 'ponds:p1', ttl: const Duration(minutes: 5), fetcher: () async => ++callA);
      expect(callA, equals(3));

      // Weather cache was preserved
      await repo.getOrFetch<int>(key: 'weather:bhimavaram', ttl: const Duration(minutes: 5), fetcher: () async => ++callB);
      expect(callB, equals(1));
    });

    test('6.5 WeatherService 3-hour cache prevents duplicate fetches across rapid calls', () async {
      final weatherService = WeatherService();

      final weather1 = await weatherService.fetchWeather();
      final weather2 = await weatherService.fetchWeather();

      // Object identity preserved via cache
      expect(identical(weather1, weather2), isTrue);

      // Force refresh produces new evaluation
      final weather3 = await weatherService.fetchWeather(forceRefresh: true);
      expect(weather3, isNotNull);
    });
  });
}
