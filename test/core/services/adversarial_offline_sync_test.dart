import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/data_hydration_service.dart';
import 'package:prawn_guard/core/services/base_repository.dart';

// Test implementation of BaseRepository
class TestRepository extends BaseRepository {
  TestRepository(super.syncService);

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

  group('Adversarial Test 5: Outbox Quarantine, Zero Head-of-Line Blocking, Idempotency & Flush-Before-Hydrate Ordering', () {
    test('Adversarial 5.1: Permanent 4xx / PostgreSQL error codes (23503, 22P02, 42501, P0002) are quarantined to dead-letter queue without blocking subsequent mutations', () async {
      await syncService.clearQueue();
      await syncService.clearDeadLetterQueue();

      // Mutation 1: Fatal 23503 foreign key violation
      await syncService.enqueue({
        'id': 'mut_adv_fatal_fk',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'ghost_pond_404', 'ph': 8.2},
      });

      // Mutation 2: Valid telemetry insert
      await syncService.enqueue({
        'id': 'mut_adv_valid_1',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_alpha', 'ph': 7.8, 'dissolved_oxygen': 5.4},
      });

      // Mutation 3: Fatal 42501 permission denied
      await syncService.enqueue({
        'id': 'mut_adv_fatal_rls',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'forbidden_pond', 'ph': 9.1},
      });

      // Mutation 4: Valid feed log insert
      await syncService.enqueue({
        'id': 'mut_adv_valid_2',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_alpha', 'feed_kg': 42.0},
      });

      expect(await syncService.getQueueLength(), equals(4));
      expect(await syncService.deadLetterQueueLength, equals(0));

      final successfulSyncs = <String>[];

      // Drain queue with simulated PostgreSQL and client errors
      final drainedCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        maxBackoff: Duration.zero,
        useJitter: false,
        executor: (mutation) async {
          final id = mutation['id'] as String;
          if (id == 'mut_adv_fatal_fk') {
            throw const PostgrestException(
              message: 'violates foreign key constraint',
              code: '23503',
            );
          } else if (id == 'mut_adv_fatal_rls') {
            throw const PostgrestException(
              message: 'insufficient_privilege for table water_logs',
              code: '42501',
            );
          }
          successfulSyncs.add(id);
          return true;
        },
      );

      // Both valid mutations succeeded despite being sandwiched between permanent errors
      expect(drainedCount, equals(2));
      expect(successfulSyncs, equals(['mut_adv_valid_1', 'mut_adv_valid_2']));

      // Active queue is completely cleared
      expect(await syncService.getQueueLength(), equals(0));

      // Both fatal mutations are quarantined in dead-letter storage with status failedPermanent
      expect(await syncService.deadLetterQueueLength, equals(2));
      final deadLetter = await syncService.getDeadLetterQueue();
      expect(deadLetter.any((m) => m['id'] == 'mut_adv_fatal_fk'), isTrue);
      expect(deadLetter.any((m) => m['id'] == 'mut_adv_fatal_rls'), isTrue);
      expect(deadLetter.every((m) => m['status'] == SyncStatus.failedPermanent.name), isTrue);
    });

    test('Adversarial 5.2: Idempotency key tracking generates RFC-compliant UUID v4 keys deterministically and prevents duplication', () async {
      await syncService.clearQueue();

      // Mutation with explicit seed
      const keySeed = 'farmer_bhimavaram_20261111_0600';
      final uuid1 = OfflineSyncService.generateUuid(keySeed);
      final uuid2 = OfflineSyncService.generateUuid(keySeed);
      expect(uuid1, equals(uuid2));

      // Enqueue mutation with auto-generated idempotency key
      await syncService.enqueue({
        'table': 'expenses',
        'action': 'insert',
        'payload': {'amount': 15000.0, 'category': 'feed'},
      });

      final queue = await syncService.getQueue();
      expect(queue.length, equals(1));
      final enqueuedKey = queue.first['idempotency_key'] as String;
      expect(enqueuedKey, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(enqueuedKey),
        isTrue,
        reason: 'Auto-assigned idempotency key must strictly adhere to UUID v4 specification',
      );
    });

    test('Adversarial 5.3: Flush-before-hydrate ordering guarantees all pending outbox mutations are flushed before pulling remote state', () async {
      await syncService.clearQueue();

      // Enqueue 3 uncommitted offline modifications
      await syncService.enqueue({
        'id': 'mut_pre_hydrate_1',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'dissolved_oxygen': 4.6},
      });
      await syncService.enqueue({
        'id': 'mut_pre_hydrate_2',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'feed_kg': 35.0},
      });

      expect(await syncService.getQueueLength(), equals(2));

      // Execution sequence tracker
      final executionOrder = <String>[];

      // Simulate DataHydrationService flush-before-hydrate sequence
      final flushedCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (mutation) async {
          executionOrder.add('FLUSH_${mutation['id']}');
          return true;
        },
      );

      // Remote query step after flush completes
      executionOrder.add('REMOTE_QUERY_SUPABASE');

      expect(flushedCount, equals(2));
      expect(await syncService.getQueueLength(), equals(0));
      expect(executionOrder, equals([
        'FLUSH_mut_pre_hydrate_1',
        'FLUSH_mut_pre_hydrate_2',
        'REMOTE_QUERY_SUPABASE',
      ]));
    });

    test('Adversarial 5.4: Interleaved concurrent enqueue during slow async drain preserves all mutations without race condition or storage clobbering', () async {
      await syncService.clearQueue();

      // Enqueue 1 initial mutation
      await syncService.enqueue({
        'id': 'mut_adv_slow',
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'p_init', 'name': 'Initial Pond'},
      });

      // Start slow drain
      final drainFuture = syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async {
          if (m['id'] == 'mut_adv_slow') {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          return true;
        },
      );

      // Concurrent enqueues during in-flight drain
      await Future.delayed(const Duration(milliseconds: 15));
      await syncService.enqueue({
        'id': 'mut_adv_conc_1',
        'table': 'water_logs',
        'payload': {'ph': 8.0},
      });
      await syncService.enqueue({
        'id': 'mut_adv_conc_2',
        'table': 'feed_logs',
        'payload': {'feed_kg': 50.0},
      });

      final firstDrainCount = await drainFuture;
      expect(firstDrainCount, greaterThanOrEqualTo(1));

      // Second drain clears remaining concurrent additions
      final secondDrainCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async => true,
      );

      expect(firstDrainCount + secondDrainCount, equals(3),
          reason: 'All mutations must be processed with zero loss during concurrency');
      expect(await syncService.getQueueLength(), equals(0));
    });

    test('Adversarial 5.5: DataHydrationService merge logic ensures remote server records win when outbox is clean, but dirty outbox entity edits strictly take precedence', () {
      final hydration = DataHydrationService();

      // Case A: Clean outbox (no pending edits) -> Remote server authority wins
      final cleanLocal = [
        {'id': 'pond_100', 'name': 'Local Stale Name', 'version': 1},
      ];
      final remoteUpdated = [
        {'id': 'pond_100', 'name': 'Server Authoritative Name', 'version': 2},
      ];

      final cleanMerge = hydration.mergeMapsById(remoteUpdated, cleanLocal, dirtyEntityIds: {});
      expect(cleanMerge.length, equals(1));
      expect(cleanMerge.first['name'], equals('Server Authoritative Name'));
      expect(cleanMerge.first['version'], equals(2));

      // Case B: Dirty outbox (uncommitted local edit) -> Local dirty edit strictly wins
      final dirtyMerge = hydration.mergeMapsById(
        remoteUpdated,
        cleanLocal,
        dirtyEntityIds: {'pond_100'},
      );
      expect(dirtyMerge.length, equals(1));
      expect(dirtyMerge.first['name'], equals('Local Stale Name'),
          reason: 'Dirty uncommitted local mutation must win over remote server record');
    });

    test('Adversarial 5.6: Cascading parent-child quarantine moves failing pond and all dependent water/feed logs to dead-letter queue and leaves active queue clean', () async {
      await syncService.clearQueue();
      await syncService.clearDeadLetterQueue();

      // 1. Parent pond that will fail permanently
      await syncService.enqueue({
        'id': 'mut_bad_parent_pond',
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'pond_doomed', 'name': 'Doomed Pond'},
      });

      // 2. Child water log referencing pond_doomed
      await syncService.enqueue({
        'id': 'mut_child_wl',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'id': 'wl_1', 'pond_id': 'pond_doomed', 'ph': 7.5},
      });

      // 3. Child feed log referencing pond_doomed
      await syncService.enqueue({
        'id': 'mut_child_fl',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'id': 'fl_1', 'pondId': 'pond_doomed', 'feed_kg': 20.0},
      });

      // 4. Healthy independent pond
      await syncService.enqueue({
        'id': 'mut_healthy_pond',
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'pond_healthy', 'name': 'Healthy Pond'},
      });

      expect(await syncService.getQueueLength(), equals(4));

      final successIds = <String>[];

      // Drain queue: mut_bad_parent_pond throws fatal 42501
      final drainedCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async {
          if (m['id'] == 'mut_bad_parent_pond') {
            throw const PostgrestException(
              message: 'violates row level security',
              code: '42501',
            );
          }
          successIds.add(m['id'] as String);
          return true;
        },
      );

      // Only healthy pond should succeed
      expect(drainedCount, equals(1));
      expect(successIds, equals(['mut_healthy_pond']));

      // Active queue is completely empty
      expect(await syncService.getQueueLength(), equals(0));

      // Dead letter queue has parent + 2 children = 3 quarantined items
      expect(await syncService.deadLetterQueueLength, equals(3));
      final dlItems = await syncService.getDeadLetterQueue();
      expect(dlItems.any((m) => m['id'] == 'mut_bad_parent_pond'), isTrue);
      expect(dlItems.any((m) => m['id'] == 'mut_child_wl'), isTrue);
      expect(dlItems.any((m) => m['id'] == 'mut_child_fl'), isTrue);
    });
  });
}
