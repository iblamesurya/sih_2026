import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/data_hydration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineSyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    syncService = OfflineSyncService(prefs);
  });

  group('OutboxMutation Model & Idempotency Key', () {
    test('OutboxMutation model serializes and deserializes accurately with SyncStatus', () {
      final mutation = OutboxMutation(
        id: 'mut_test_1',
        idempotencyKey: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        table: 'water_logs',
        operation: 'INSERT',
        payload: const {'pond_id': 'p1', 'ph': 7.8, 'do': 5.2},
        baseVersion: 2,
        createdAt: DateTime.utc(2026, 11, 11, 12, 0, 0),
        retryCount: 1,
        status: SyncStatus.pending,
      );

      final json = mutation.toJson();
      expect(json['id'], equals('mut_test_1'));
      expect(json['idempotency_key'], equals('a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d'));
      expect(json['table'], equals('water_logs'));
      expect(json['operation'], equals('INSERT'));
      expect(json['base_version'], equals(2));
      expect(json['status'], equals('pending'));

      final restored = OutboxMutation.fromJson(json);
      expect(restored.id, equals(mutation.id));
      expect(restored.idempotencyKey, equals(mutation.idempotencyKey));
      expect(restored.table, equals(mutation.table));
      expect(restored.operation, equals(mutation.operation));
      expect(restored.baseVersion, equals(mutation.baseVersion));
      expect(restored.status, equals(SyncStatus.pending));

      // OfflineMutation typedef compatibility
      expect(mutation, isA<OfflineMutation>());
    });

    test('generateUuid produces valid 8-4-4-4-12 hex UUID v4 format', () {
      final uuid = OfflineSyncService.generateUuid();
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(uuid), isTrue);

      final seeded1 = OfflineSyncService.generateUuid('seed_alpha');
      final seeded2 = OfflineSyncService.generateUuid('seed_alpha');
      expect(seeded1, equals(seeded2));
    });

    test('enqueue automatically populates idempotencyKey UUID if omitted', () async {
      await syncService.enqueue({
        'table': 'ponds',
        'action': 'insert',
        'payload': {'name': 'Pond 5'},
      });

      final queue = await syncService.getQueue();
      expect(queue.length, equals(1));
      expect(queue.first['idempotency_key'], isNotNull);
      expect(queue.first['idempotencyKey'], isNotNull);
      expect(queue.first['operation'], equals('INSERT'));
      expect(queue.first['base_version'], equals(1));
    });
  });

  group('Permanent Error Detection & Head-of-Line Blocking Elimination', () {
    test('isPermanentError detects PostgreSQL codes 23503, 22P02, 42501, P0002 and 4xx', () {
      expect(
        OfflineSyncService.isPermanentError(
          const PostgrestException(message: 'foreign key constraint', code: '23503'),
        ),
        isTrue,
      );
      expect(
        OfflineSyncService.isPermanentError(
          const PostgrestException(message: 'invalid input syntax for type uuid', code: '22P02'),
        ),
        isTrue,
      );
      expect(
        OfflineSyncService.isPermanentError(
          const PostgrestException(message: 'insufficient_privilege', code: '42501'),
        ),
        isTrue,
      );
      expect(
        OfflineSyncService.isPermanentError(
          const PostgrestException(message: 'optimistic lock failed', code: 'P0002'),
        ),
        isTrue,
      );
      expect(
        OfflineSyncService.isPermanentError(
          const PermanentSyncException('Validation failed', code: '400'),
        ),
        isTrue,
      );
      expect(
        OfflineSyncService.isPermanentError(
          Exception('PostgreSQL error code: 23503 violates foreign key'),
        ),
        isTrue,
      );

      // Transient errors must NOT be permanent
      expect(OfflineSyncService.isPermanentError(Exception('SocketException: Connection refused')), isFalse);
      expect(OfflineSyncService.isPermanentError(Exception('TimeoutException: 504 Gateway Timeout')), isFalse);
    });

    test('Permanent client error is quarantined to dead-letter queue and does NOT block subsequent valid mutations', () async {
      // 1. Enqueue bad mutation that triggers permanent 23503 (FK error)
      await syncService.enqueue({
        'id': 'mut_bad_fk',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'non_existent_pond_999'},
      });

      // 2. Enqueue valid mutation 1
      await syncService.enqueue({
        'id': 'mut_good_1',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'ph': 7.9},
      });

      // 3. Enqueue valid mutation 2
      await syncService.enqueue({
        'id': 'mut_good_2',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'feed_kg': 25.0},
      });

      expect(await syncService.queueLength, equals(3));
      expect(await syncService.deadLetterQueueLength, equals(0));

      final processedIds = <String>[];

      // Executor that throws permanent exception for mut_bad_fk, succeeds for good ones
      final drainedCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        maxBackoff: Duration.zero,
        useJitter: false,
        executor: (mutation) async {
          final id = mutation['id'] as String;
          if (id == 'mut_bad_fk') {
            throw const PostgrestException(
              message: 'insert or update on table water_logs violates foreign key constraint',
              code: '23503',
            );
          }
          processedIds.add(id);
          return true;
        },
      );

      // Both valid mutations must have succeeded!
      expect(drainedCount, equals(2));
      expect(processedIds, equals(['mut_good_1', 'mut_good_2']));

      // Active queue is completely cleared
      expect(await syncService.queueLength, equals(0));

      // Bad mutation is quarantined in dead letter queue with failedPermanent status
      expect(await syncService.deadLetterQueueLength, equals(1));
      final deadLetter = await syncService.getDeadLetterQueue();
      expect(deadLetter.first['id'], equals('mut_bad_fk'));
      expect(deadLetter.first['status'], equals(SyncStatus.failedPermanent.name));
      expect(deadLetter.first['last_error'], contains('23503'));
    });

    test('clearDeadLetterQueue empties quarantined items without affecting active queue', () async {
      await syncService.enqueue({'id': 'mut_bad', 'table': 'ponds'});
      await syncService.enqueue({'id': 'mut_good', 'table': 'ponds'});

      await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async {
          if (m['id'] == 'mut_bad') {
            throw const PermanentSyncException('Version conflict', code: 'P0002');
          }
          return true;
        },
      );

      expect(await syncService.deadLetterQueueLength, equals(1));
      await syncService.clearDeadLetterQueue();
      expect(await syncService.deadLetterQueueLength, equals(0));
    });
  });

  group('Flush-Before-Hydrate Ordering', () {
    test('flushPendingOutbox flushes outbox mutations before hydration', () async {
      await syncService.enqueue({
        'table': 'water_logs',
        'payload': {'pond_id': 'pond_1', 'ph': 8.0},
      });
      expect(await syncService.queueLength, equals(1));

      // Flush outbox
      final flushed = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async => true,
      );

      expect(flushed, equals(1));
      expect(await syncService.queueLength, equals(0));
    });
  });

  group('Bug 1 Fix: Atomic Outbox Queue Drain & Concurrent Enqueue Race Condition Elimination', () {
    test('Concurrent enqueue() during in-flight slow drainQueue() is NOT clobbered and is fully preserved', () async {
      // 1. Enqueue initial slow mutation
      await syncService.enqueue({
        'id': 'mut_slow_1',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'ph': 7.2},
      });

      expect(await syncService.getQueueLength(), equals(1));

      // 2. Start drain with an executor that pauses on mut_slow_1
      final drainFuture = syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (mutation) async {
          if (mutation['id'] == 'mut_slow_1') {
            await Future.delayed(const Duration(milliseconds: 60));
          }
          return true;
        },
      );

      // 3. Concurrently enqueue new mutations while mut_slow_1 is in-flight
      await Future.delayed(const Duration(milliseconds: 20));
      await syncService.enqueue({
        'id': 'mut_concurrent_2',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'feed_kg': 15.0},
      });
      await syncService.enqueue({
        'id': 'mut_concurrent_3',
        'table': 'expenses',
        'action': 'insert',
        'payload': {'amount': 2500.0, 'category': 'labor'},
      });

      // 4. Await completion of drain
      final drainedCount = await drainFuture;
      expect(drainedCount, greaterThanOrEqualTo(1));

      // 5. Drain any remaining mutations
      final secondDrain = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async => true,
      );

      // Total processed across both drains must be 3, with zero mutations lost!
      expect(drainedCount + secondDrain, equals(3));
      expect(await syncService.getQueueLength(), equals(0));
    });
  });

  group('Bug 2 Fix: Hydration Merge Bug - Clean Local vs Dirty Outbox vs Remote Authority', () {
    final hydration = DataHydrationService();

    test('Clean local cache does NOT overwrite newer remote server record', () {
      final local = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Stale Local)',
          'updated_at': '2026-11-10T10:00:00Z',
          'version': 1,
        },
      ];

      final remote = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Updated by Web Admin)',
          'updated_at': '2026-11-11T15:00:00Z',
          'version': 2,
        },
      ];

      // No dirty mutations for pond_1
      final merged = hydration.mergeMapsById(remote, local, dirtyEntityIds: {});
      expect(merged.length, equals(1));
      expect(merged.first['name'], equals('Pond 1 (Updated by Web Admin)'));
      expect(merged.first['version'], equals(2));
    });

    test('Dirty local entity with uncommitted outbox mutation ALWAYS wins over remote server state', () {
      final local = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Local Offline Edit)',
          'updated_at': '2026-11-11T12:00:00Z',
          'version': 1,
        },
      ];

      final remote = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Remote Base)',
          'updated_at': '2026-11-11T14:00:00Z',
          'version': 2,
        },
      ];

      // Entity pond_1 has pending uncommitted mutations in the offline outbox
      final merged = hydration.mergeMapsById(
        remote,
        local,
        dirtyEntityIds: {'pond_1'},
      );
      expect(merged.length, equals(1));
      expect(merged.first['name'], equals('Pond 1 (Local Offline Edit)'));
    });

    test('Local entity with strictly newer timestamp or version wins over remote when clean', () {
      final local = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Newer Local Timestamp)',
          'updated_at': '2026-11-11T16:00:00Z',
        },
      ];

      final remote = [
        {
          'id': 'pond_1',
          'name': 'Pond 1 (Older Remote Timestamp)',
          'updated_at': '2026-11-11T10:00:00Z',
        },
      ];

      final merged = hydration.mergeMapsById(remote, local, dirtyEntityIds: {});
      expect(merged.length, equals(1));
      expect(merged.first['name'], equals('Pond 1 (Newer Local Timestamp)'));
    });

    test('Local-only and remote-only records are preserved during merge', () {
      final local = [
        {'id': 'pond_local_only', 'name': 'Offline Created Pond'},
      ];

      final remote = [
        {'id': 'pond_remote_only', 'name': 'Server Created Pond'},
      ];

      final merged = hydration.mergeMapsById(remote, local, dirtyEntityIds: {});
      expect(merged.length, equals(2));
      expect(merged.any((p) => p['id'] == 'pond_local_only'), isTrue);
      expect(merged.any((p) => p['id'] == 'pond_remote_only'), isTrue);
    });

    test('OfflineSyncService.getDirtyEntityIds() correctly identifies uncommitted entity IDs from queue', () async {
      await syncService.clearQueue();

      await syncService.enqueue({
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'pond_dirty_1', 'name': 'Pond Dirty 1'},
      });

      await syncService.enqueue({
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'id': 'log_dirty_2', 'pond_id': 'pond_dirty_1'},
      });

      await syncService.enqueue({
        'table': 'ponds',
        'action': 'update',
        'target_id': 'pond_dirty_3',
        'payload': {'name': 'Pond Dirty 3 Updated'},
      });

      final dirtyIds = await syncService.getDirtyEntityIds();
      expect(dirtyIds.contains('pond_dirty_1'), isTrue);
      expect(dirtyIds.contains('log_dirty_2'), isTrue);
      expect(dirtyIds.contains('pond_dirty_3'), isTrue);
    });
  });

  group('Bug 6 Fix: Cascading Parent-Child Quarantine on Offline Pond Creation Failure', () {
    test('When parent pond creation fails permanently, cascading quarantine moves parent and all dependent child mutations to dead-letter queue', () async {
      await syncService.clearQueue();
      await syncService.clearDeadLetterQueue();

      // 1. Parent pond creation destined to fail permanently
      await syncService.enqueue({
        'id': 'mut_pond_parent_fail',
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'pond_bad_parent', 'name': 'Faulty Pond'},
      });

      // 2. Child water log referencing pond_bad_parent (via pond_id)
      await syncService.enqueue({
        'id': 'mut_child_water_log',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'id': 'wl_101', 'pond_id': 'pond_bad_parent', 'ph': 7.6},
      });

      // 3. Child feed log referencing pond_bad_parent (via pondId)
      await syncService.enqueue({
        'id': 'mut_child_feed_log',
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'id': 'fl_202', 'pondId': 'pond_bad_parent', 'feed_kg': 40.0},
      });

      // 4. Independent valid pond creation
      await syncService.enqueue({
        'id': 'mut_pond_good_parent',
        'table': 'ponds',
        'action': 'insert',
        'payload': {'id': 'pond_good_parent', 'name': 'Healthy Pond'},
      });

      // 5. Independent valid child water log referencing pond_good_parent
      await syncService.enqueue({
        'id': 'mut_good_child_water_log',
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'id': 'wl_303', 'pond_id': 'pond_good_parent', 'ph': 8.1},
      });

      expect(await syncService.getQueueLength(), equals(5));
      expect(await syncService.deadLetterQueueLength, equals(0));

      final processedIds = <String>[];

      // Drain the queue. Parent mut_pond_parent_fail throws permanent 42501 (RLS rejection).
      final drainedCount = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        maxBackoff: Duration.zero,
        useJitter: false,
        executor: (mutation) async {
          final id = mutation['id'] as String;
          if (id == 'mut_pond_parent_fail') {
            throw const PostgrestException(
              message: 'new row violates row-level security policy for table "ponds"',
              code: '42501',
            );
          }
          processedIds.add(id);
          return true;
        },
      );

      // Independent mutations succeeded!
      expect(drainedCount, equals(2));
      expect(processedIds, equals(['mut_pond_good_parent', 'mut_good_child_water_log']));

      // Active queue is completely cleared (no lingering mutations!)
      expect(await syncService.getQueueLength(), equals(0));

      // Dead letter queue contains exactly 3 items: the failed parent pond and both child mutations!
      expect(await syncService.deadLetterQueueLength, equals(3));
      final deadLetter = await syncService.getDeadLetterQueue();

      final parentDl = deadLetter.firstWhere((m) => m['id'] == 'mut_pond_parent_fail');
      expect(parentDl['status'], equals(SyncStatus.failedPermanent.name));
      expect(parentDl['last_error'], contains('42501'));

      final childWaterDl = deadLetter.firstWhere((m) => m['id'] == 'mut_child_water_log');
      expect(childWaterDl['status'], equals(SyncStatus.failedPermanent.name));
      expect(
        childWaterDl['last_error'],
        equals('Blocked by failed parent pond creation: pond_bad_parent'),
      );

      final childFeedDl = deadLetter.firstWhere((m) => m['id'] == 'mut_child_feed_log');
      expect(childFeedDl['status'], equals(SyncStatus.failedPermanent.name));
      expect(
        childFeedDl['last_error'],
        equals('Blocked by failed parent pond creation: pond_bad_parent'),
      );
    });
  });
}
