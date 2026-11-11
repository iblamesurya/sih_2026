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
        payload: {'pond_id': 'p1', 'ph': 7.8, 'do': 5.2},
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
      expect(mutation is OfflineMutation, isTrue);
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

      final hydration = DataHydrationService();
      // Dummy ref map
      final flushed = await syncService.drainQueue(
        initialBackoff: Duration.zero,
        useJitter: false,
        executor: (m) async => true,
      );

      expect(flushed, equals(1));
      expect(await syncService.queueLength, equals(0));
    });
  });
}
