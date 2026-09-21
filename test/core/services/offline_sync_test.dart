import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineSyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    syncService = OfflineSyncService(prefs);
  });

  group('OfflineSyncService - FIFO Queue & Capacity Constraints', () {
    test('enqueues mutations with metadata and retrieves them in FIFO order', () async {
      await syncService.enqueue({
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'ph': 8.1, 'do': 5.5},
      });

      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': 'pond_1', 'feed_kg': 25.0},
      });

      final queue = await syncService.getQueue();
      expect(queue.length, equals(2));
      expect(queue[0]['table'], equals('water_logs'));
      expect(queue[0]['status'], equals('pending'));
      expect(queue[0]['id'], isNotNull);
      expect(queue[0]['created_at'], isNotNull);
      expect(queue[1]['table'], equals('feed_logs'));
      expect(await syncService.queueLength, equals(2));
    });

    test('strictly caps queue at 100 items and drops oldest entry on overflow (FIFO)', () async {
      // Enqueue exactly 100 items
      for (int i = 0; i < 100; i++) {
        await syncService.enqueue({
          'item_index': i,
          'table': 'water_logs',
          'payload': {'reading': i},
        });
      }

      expect(await syncService.queueLength, equals(100));
      var queue = await syncService.getQueue();
      expect(queue.first['item_index'], equals(0));
      expect(queue.last['item_index'], equals(99));

      // Enqueue 101st item
      await syncService.enqueue({
        'item_index': 100,
        'table': 'water_logs',
        'payload': {'reading': 100},
      });

      expect(await syncService.queueLength, equals(100));
      queue = await syncService.getQueue();

      // Oldest item (index 0) must be evicted, index 1 is now the front
      expect(queue.first['item_index'], equals(1));
      expect(queue.last['item_index'], equals(100));

      // Add 20 more items
      for (int i = 101; i <= 120; i++) {
        await syncService.enqueue({
          'item_index': i,
          'table': 'water_logs',
          'payload': {'reading': i},
        });
      }

      expect(await syncService.queueLength, equals(100));
      queue = await syncService.getQueue();
      expect(queue.first['item_index'], equals(21));
      expect(queue.last['item_index'], equals(120));
    });

    test('clears queue completely when requested', () async {
      await syncService.enqueue({'table': 'test', 'payload': {}});
      await syncService.enqueue({'table': 'test2', 'payload': {}});
      expect(await syncService.queueLength, equals(2));

      await syncService.clearQueue();
      expect(await syncService.queueLength, equals(0));
      expect(await syncService.getQueue(), isEmpty);
    });

    test('drainQueue processes items sequentially and stops on persistent failure', () async {
      final processedItems = <int>[];

      for (int i = 0; i < 5; i++) {
        await syncService.enqueue({
          'item_index': i,
          'table': 'water_logs',
          'payload': {'val': i},
        });
      }

      // Executor succeeds on 0 and 1, fails on 2
      final drainedCount = await syncService.drainQueue(
        executor: (mutation) async {
          final index = mutation['item_index'] as int;
          if (index == 2) {
            return false; // Simulate failure
          }
          processedItems.add(index);
          return true;
        },
        maxRetriesPerItem: 2,
        initialBackoff: const Duration(milliseconds: 10),
      );

      expect(drainedCount, equals(2));
      expect(processedItems, equals([0, 1]));

      // Remaining queue must preserve item 2, 3, 4
      final remaining = await syncService.getQueue();
      expect(remaining.length, equals(3));
      expect(remaining[0]['item_index'], equals(2));
      expect(remaining[1]['item_index'], equals(3));
      expect(remaining[2]['item_index'], equals(4));
    });

    test('drainQueue successfully empties queue when all items succeed', () async {
      for (int i = 0; i < 3; i++) {
        await syncService.enqueue({
          'item_index': i,
          'table': 'disease_scans',
        });
      }

      final drainedCount = await syncService.drainQueue(
        executor: (mutation) async => true,
      );

      expect(drainedCount, equals(3));
      expect(await syncService.queueLength, equals(0));
    });
  });
}
