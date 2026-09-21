import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/base_repository.dart';

// Test implementation of BaseRepository
class TestRepository extends BaseRepository {
  TestRepository(OfflineSyncService syncService) : super(syncService);

  Future<Map<String, dynamic>?> recordWaterLog({
    required Future<Map<String, dynamic>> Function() action,
    required Map<String, dynamic> offlineMutation,
    Map<String, dynamic>? fallback,
    bool rethrowIfNoFallback = false,
  }) {
    return safeMutate<Map<String, dynamic>>(
      networkAction: action,
      offlineMutation: offlineMutation,
      fallbackValue: fallback,
      rethrowIfNoFallback: rethrowIfNoFallback,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late OfflineSyncService syncService;
  late TestRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    syncService = OfflineSyncService(prefs);
    repository = TestRepository(syncService);
  });

  group('Adversarial Test 1: Capacity & FIFO Boundary (100 & 105 mutations)', () {
    test('Enqueueing exactly 100 mutations yields count of 100 and perfect sequential order', () async {
      for (int i = 0; i < 100; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'water_logs',
          'payload': {'reading': i, 'ph': 7.5 + (i * 0.01)},
        });
      }

      final length = await syncService.getQueueLength();
      expect(length, equals(100), reason: 'Queue must contain exactly 100 items');

      final queue = await syncService.getQueue();
      expect(queue.length, equals(100));

      // Verify every single element from 0 to 99 is intact and in exact FIFO order
      for (int i = 0; i < 100; i++) {
        expect(queue[i]['seq_id'], equals(i),
            reason: 'Item at index $i must have seq_id $i');
        expect(queue[i]['status'], equals('pending'));
        expect(queue[i]['id'], isNotNull);
        expect(queue[i]['created_at'], isNotNull);
      }
    });

    test('Enqueueing 105 mutations strictly caps at 100 and drops the first 5 in exact FIFO order', () async {
      // Enqueue 105 mutations sequentially
      for (int i = 0; i < 105; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'feed_logs',
          'payload': {'batch': 'pond_alpha', 'feed_kg': i * 1.5},
        });
      }

      final length = await syncService.getQueueLength();
      expect(length, equals(100), reason: 'Queue capacity must remain hard-capped at 100');

      final queue = await syncService.getQueue();
      expect(queue.length, equals(100), reason: 'Retrieved queue length must be exactly 100');

      // The first 5 mutations (seq_id 0, 1, 2, 3, 4) must have been evicted
      // The remaining mutations in the queue must strictly be seq_id 5 through 104
      expect(queue.first['seq_id'], equals(5),
          reason: 'Head of queue must be seq_id 5 after dropping first 5 items');
      expect(queue.last['seq_id'], equals(104),
          reason: 'Tail of queue must be seq_id 104');

      for (int index = 0; index < 100; index++) {
        final expectedSeqId = index + 5;
        expect(queue[index]['seq_id'], equals(expectedSeqId),
            reason: 'Queue position $index must contain seq_id $expectedSeqId');
      }
    });

    test('Extreme stress: Enqueueing 300 mutations maintains strict 100-cap and retains last 100 (200..299)', () async {
      for (int i = 0; i < 300; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'expenses',
          'payload': {'amount': i * 100},
        });
      }

      expect(await syncService.getQueueLength(), equals(100));
      final queue = await syncService.getQueue();
      expect(queue.first['seq_id'], equals(200));
      expect(queue.last['seq_id'], equals(299));
    });
  });

  group('Adversarial Test 2: drainQueue Sequencing, Exponential Backoff & Error Semantics', () {
    test('drainQueue executes strictly sequentially in FIFO order', () async {
      final executionOrder = <int>[];

      for (int i = 0; i < 10; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'water_logs',
        });
      }

      final drained = await syncService.drainQueue(
        executor: (mutation) async {
          executionOrder.add(mutation['seq_id'] as int);
          return true;
        },
      );

      expect(drained, equals(10));
      expect(executionOrder, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
      expect(await syncService.getQueueLength(), equals(0));
    });

    test('drainQueue retries retryable errors and succeeds after transient failure', () async {
      final attemptCounts = <int, int>{};

      for (int i = 0; i < 3; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'disease_scans',
        });
      }

      final drained = await syncService.drainQueue(
        maxRetriesPerItem: 3,
        initialBackoff: const Duration(milliseconds: 5),
        executor: (mutation) async {
          final id = mutation['seq_id'] as int;
          attemptCounts[id] = (attemptCounts[id] ?? 0) + 1;

          // Item 1 fails on attempt 1, succeeds on attempt 2
          if (id == 1 && attemptCounts[id]! < 2) {
            return false;
          }
          return true;
        },
      );

      expect(drained, equals(3), reason: 'All 3 items should eventually succeed');
      expect(attemptCounts[0], equals(1));
      expect(attemptCounts[1], equals(2), reason: 'Item 1 should have retried once before succeeding');
      expect(attemptCounts[2], equals(1));
      expect(await syncService.getQueueLength(), equals(0));
    });

    test('drainQueue halts on persistent failure after maxRetries, preserving remaining items and FIFO order', () async {
      final attempts = <int, int>{};

      for (int i = 0; i < 4; i++) {
        await syncService.enqueue({
          'seq_id': i,
          'table': 'harvests',
        });
      }

      final drained = await syncService.drainQueue(
        maxRetriesPerItem: 3,
        initialBackoff: const Duration(milliseconds: 5),
        executor: (mutation) async {
          final id = mutation['seq_id'] as int;
          attempts[id] = (attempts[id] ?? 0) + 1;

          // Item 1 persistently fails
          if (id == 1) {
            return false;
          }
          return true;
        },
      );

      // Item 0 succeeds; Item 1 fails 3 times; execution halts so Items 2 and 3 are NOT attempted
      expect(drained, equals(1));
      expect(attempts[0], equals(1));
      expect(attempts[1], equals(3), reason: 'Item 1 should have been retried 3 times before giving up');
      expect(attempts[2], isNull, reason: 'Item 2 must NOT be processed after Item 1 failure');
      expect(attempts[3], isNull);

      final remaining = await syncService.getQueue();
      expect(remaining.length, equals(3));
      expect(remaining[0]['seq_id'], equals(1), reason: 'Failed item 1 must remain at head of queue');
      expect(remaining[1]['seq_id'], equals(2));
      expect(remaining[2]['seq_id'], equals(3));
    });

    test('drainQueue handles unexpected unhandled exception in executor gracefully', () async {
      for (int i = 0; i < 3; i++) {
        await syncService.enqueue({'seq_id': i, 'table': 'ponds'});
      }

      final drained = await syncService.drainQueue(
        maxRetriesPerItem: 2,
        initialBackoff: const Duration(milliseconds: 5),
        executor: (mutation) async {
          if (mutation['seq_id'] == 1) {
            throw Exception('Severe fatal database crash');
          }
          return true;
        },
      );

      expect(drained, equals(1));
      final remaining = await syncService.getQueue();
      expect(remaining.length, equals(2));
      expect(remaining[0]['seq_id'], equals(1));
    });

    test('drainQueue skips and cleans up corrupted non-JSON items without crashing', () async {
      // Enqueue valid item 0
      await syncService.enqueue({'seq_id': 0, 'table': 'water_logs'});

      // Inject corrupted item directly into SharedPreferences
      final rawList = prefs.getStringList(OfflineSyncService.queueKey) ?? [];
      rawList.add('INVALID_JSON{{{broken');
      rawList.add('{"seq_id": 2, "table": "water_logs", "status": "pending"}');
      await prefs.setStringList(OfflineSyncService.queueKey, rawList);

      final drained = await syncService.drainQueue(
        executor: (mutation) async => true,
      );

      expect(drained, equals(2), reason: 'Items 0 and 2 should succeed, corrupted item skipped');
      expect(await syncService.getQueueLength(), equals(0));
    });
  });

  group('Adversarial Test 3: BaseRepository safeMutate Network Exception Interception', () {
    test('safeMutate catches SocketException, enqueues mutation, and returns fallbackValue', () async {
      final offlinePayload = {
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'do': 4.2},
      };

      final fallback = {'status': 'offline_queued', 'pond_id': 'pond_1'};

      final result = await repository.recordWaterLog(
        action: () async => throw const SocketException('OS: Network is unreachable (errno = 101)'),
        offlineMutation: offlinePayload,
        fallback: fallback,
      );

      expect(result, equals(fallback));
      expect(await syncService.getQueueLength(), equals(1));
      final queued = (await syncService.getQueue()).first;
      expect(queued['table'], equals('water_logs'));
      expect(queued['payload']['do'], equals(4.2));
      expect(queued['status'], equals('pending'));
    });

    test('safeMutate catches TimeoutException, enqueues mutation, and returns null when no fallback provided', () async {
      final offlinePayload = {
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_2', 'feed_kg': 50.0},
      };

      final result = await repository.recordWaterLog(
        action: () async => throw TimeoutException('Connection timed out after 10000ms', const Duration(seconds: 10)),
        offlineMutation: offlinePayload,
      );

      expect(result, isNull);
      expect(await syncService.getQueueLength(), equals(1));
      final queued = (await syncService.getQueue()).first;
      expect(queued['table'], equals('feed_logs'));
      expect(queued['payload']['feed_kg'], equals(50.0));
    });

    test('safeMutate catches http.ClientException and enqueues mutation', () async {
      final offlinePayload = {
        'table': 'growth_samples',
        'action': 'insert',
        'payload': {'pond_id': 'pond_3', 'abw': 18.5},
      };

      final result = await repository.recordWaterLog(
        action: () async => throw http.ClientException('Connection closed before full headers received'),
        offlineMutation: offlinePayload,
      );

      expect(result, isNull);
      expect(await syncService.getQueueLength(), equals(1));
    });

    test('safeMutate catches network-related PostgrestException and enqueues mutation', () async {
      final offlinePayload = {
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_4', 'temp': 29.5},
      };

      final result = await repository.recordWaterLog(
        action: () async => throw const PostgrestException(
          message: 'Failed to fetch upstream response (connection timeout)',
          code: '08006',
        ),
        offlineMutation: offlinePayload,
      );

      expect(result, isNull);
      expect(await syncService.getQueueLength(), equals(1));
    });

    test('safeMutate throws OfflineQueuedException when rethrowIfNoFallback is true on SocketException', () async {
      final offlinePayload = {
        'table': 'harvests',
        'action': 'insert',
        'payload': {'tonnage': 5.2},
      };

      await expectLater(
        () => repository.recordWaterLog(
          action: () async => throw const SocketException('No route to host'),
          offlineMutation: offlinePayload,
          rethrowIfNoFallback: true,
        ),
        throwsA(isA<OfflineQueuedException>()),
      );

      // Verify mutation was still queued before exception was rethrown
      expect(await syncService.getQueueLength(), equals(1));
    });

    test('safeMutate passes through successful networkAction without enqueuing', () async {
      final offlinePayload = {'table': 'water_logs', 'action': 'insert'};

      final result = await repository.recordWaterLog(
        action: () async => {'id': 'remote_123', 'status': 'synced'},
        offlineMutation: offlinePayload,
      );

      expect(result, equals({'id': 'remote_123', 'status': 'synced'}));
      expect(await syncService.getQueueLength(), equals(0),
          reason: 'Successful network actions must not enqueue mutations');
    });

    test('safeMutate rethrows non-network exceptions (FormatException, constraint errors) WITHOUT enqueuing', () async {
      final offlinePayload = {'table': 'water_logs', 'action': 'insert'};

      // FormatException
      await expectLater(
        () => repository.recordWaterLog(
          action: () async => throw const FormatException('Invalid JSON payload structure'),
          offlineMutation: offlinePayload,
        ),
        throwsA(isA<FormatException>()),
      );

      // Non-network Postgrest error (e.g. unique violation)
      await expectLater(
        () => repository.recordWaterLog(
          action: () async => throw const PostgrestException(
            message: 'duplicate key value violates unique constraint "ponds_pkey"',
            code: '23505',
          ),
          offlineMutation: offlinePayload,
        ),
        throwsA(isA<PostgrestException>()),
      );

      expect(await syncService.getQueueLength(), equals(0),
          reason: 'Non-network errors must not be queued as offline mutations');
    });
  });

  group('Adversarial Test 4: Multilingual & Complex Payloads', () {
    test('correctly preserves Telugu Unicode characters, nested telemetry, and null fields', () async {
      final complexMutation = {
        'table': 'water_logs',
        'action': 'insert',
        'payload': {
          'pond_name': 'చెరువు నెం 1 (తాడేపల్లిగూడెం)',
          'notes': 'నీటి రంగు ఆకుపచ్చగా మారింది. ఆక్సిజన్ తక్కువగా ఉంది.',
          'telemetry': {
            'ph': 7.8,
            'dissolved_oxygen': 3.2,
            'ammonia': 0.08,
            'salinity': null,
          },
          'tags': ['తెలుగు', 'అత్యవసరం', 'DO_LOW'],
        },
      };

      await syncService.enqueue(complexMutation);

      final queue = await syncService.getQueue();
      expect(queue.length, equals(1));
      final item = queue.first;
      expect(item['payload']['pond_name'], equals('చెరువు నెం 1 (తాడేపల్లిగూడెం)'));
      expect(item['payload']['notes'], equals('నీటి రంగు ఆకుపచ్చగా మారింది. ఆక్సిజన్ తక్కువగా ఉంది.'));
      expect(item['payload']['telemetry']['dissolved_oxygen'], equals(3.2));
      expect(item['payload']['telemetry']['salinity'], isNull);
      expect(item['payload']['tags'], equals(['తెలుగు', 'అత్యవసరం', 'DO_LOW']));
    });
  });
}
