import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_client.dart';

/// Offline Synchronization Service managing a strictly FIFO mutation queue
/// persisted in [SharedPreferences] with a hard capacity of 100 items.
class OfflineSyncService {
  static const String queueKey = 'offline_queue';
  static const int maxQueueCapacity = 100;

  static Future<void>? _enqueueLock;
  static Future<int>? _activeDrainFuture;
  static bool _isDraining = false;

  /// Whether a drain cycle is currently running.
  bool get isDraining => _isDraining;

  final SharedPreferences? _injectedPrefs;

  OfflineSyncService([this._injectedPrefs]);

  Future<SharedPreferences> get _prefs async {
    final injected = _injectedPrefs;
    if (injected != null) {
      return injected;
    }
    return SharedPreferences.getInstance();
  }

  /// Adds a mutation to the offline queue with strict FIFO ordering.
  ///
  /// Serialized with an internal mutex to prevent race conditions during
  /// rapid concurrent enqueue calls. If the queue is at maximum capacity (100 items),
  /// the oldest entry (index 0) is discarded to accommodate the new mutation.
  Future<void> enqueue(Map<String, dynamic> mutation) async {
    final previousLock = _enqueueLock;
    final completer = Completer<void>();
    _enqueueLock = completer.future;

    if (previousLock != null) {
      try {
        await previousLock;
      } catch (_) {}
    }

    try {
      final prefs = await _prefs;
      final currentList = prefs.getStringList(queueKey) ?? [];

      // Create a mutable copy of the mutation with metadata
      final enrichedMutation = Map<String, dynamic>.from(mutation);
      enrichedMutation.putIfAbsent(
        'id',
        () => 'mut_${DateTime.now().microsecondsSinceEpoch}',
      );
      enrichedMutation.putIfAbsent(
        'created_at',
        () => DateTime.now().toUtc().toIso8601String(),
      );
      enrichedMutation.putIfAbsent('status', () => 'pending');
      enrichedMutation.putIfAbsent('retry_count', () => 0);

      final encoded = jsonEncode(enrichedMutation);
      final List<String> updatedList = List<String>.from(currentList);

      // If capacity reached, evict oldest entries from the front (FIFO)
      while (updatedList.length >= maxQueueCapacity) {
        updatedList.removeAt(0);
      }

      updatedList.add(encoded);
      await prefs.setStringList(queueKey, updatedList);

      if (kDebugMode) {
        debugPrint(
          'OfflineSyncService: Enqueued mutation ${enrichedMutation['id']}. Queue size: ${updatedList.length}',
        );
      }
    } finally {
      completer.complete();
    }
  }

  /// Retrieves the current list of pending mutations in strict FIFO order.
  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(queueKey) ?? [];
    final List<Map<String, dynamic>> queue = [];

    for (final raw in list) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          queue.add(decoded);
        } else if (decoded is Map) {
          queue.add(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('OfflineSyncService: Failed to parse queued item: $e');
        }
      }
    }

    return queue;
  }

  /// Returns the current number of pending items in the queue.
  Future<int> get queueLength async {
    final prefs = await _prefs;
    return (prefs.getStringList(queueKey) ?? []).length;
  }

  /// Alias method for getting the queue length.
  Future<int> getQueueLength() => queueLength;

  /// Clears all pending mutations from storage.
  Future<void> clearQueue() async {
    final prefs = await _prefs;
    await prefs.remove(queueKey);
  }

  /// Sequentially drains all pending mutations with exponential backoff on errors.
  ///
  /// Protected by a re-entrancy mutex: if a drain cycle is already executing,
  /// subsequent calls will await the active drain instead of launching a competing
  /// concurrent loop, preventing race conditions and duplicated mutations.
  Future<int> drainQueue({
    Future<bool> Function(Map<String, dynamic> mutation)? executor,
    int maxRetriesPerItem = 3,
    Duration initialBackoff = const Duration(milliseconds: 200),
    Duration maxBackoff = const Duration(seconds: 4),
  }) async {
    if (_isDraining && _activeDrainFuture != null) {
      return _activeDrainFuture!;
    }

    final future = _internalDrain(
      executor: executor,
      maxRetriesPerItem: maxRetriesPerItem,
      initialBackoff: initialBackoff,
      maxBackoff: maxBackoff,
    );
    _activeDrainFuture = future;

    try {
      return await future;
    } finally {
      _activeDrainFuture = null;
    }
  }

  Future<int> _internalDrain({
    Future<bool> Function(Map<String, dynamic> mutation)? executor,
    int maxRetriesPerItem = 3,
    Duration initialBackoff = const Duration(milliseconds: 200),
    Duration maxBackoff = const Duration(seconds: 4),
  }) async {
    _isDraining = true;
    try {
      final prefs = await _prefs;
      final currentList = prefs.getStringList(queueKey) ?? [];
      if (currentList.isEmpty) {
        return 0;
      }

      final List<String> remainingList = List<String>.from(currentList);
      int successCount = 0;

      while (remainingList.isNotEmpty) {
        final rawItem = remainingList.first;
        Map<String, dynamic> mutation;
        try {
          final decoded = jsonDecode(rawItem);
          mutation = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded as Map);
        } catch (e) {
          // Corrupted item, remove it
          remainingList.removeAt(0);
          await prefs.setStringList(queueKey, remainingList);
          continue;
        }

        int attempts = 0;
        bool success = false;
        Duration currentBackoff = initialBackoff;

        while (attempts < maxRetriesPerItem && !success) {
          attempts++;
          try {
            if (executor != null) {
              success = await executor(mutation);
            } else {
              success = await _defaultExecutor(mutation);
            }
          } catch (e) {
            success = false;
            if (kDebugMode) {
              debugPrint(
                'OfflineSyncService: Error draining item ${mutation['id']} (attempt $attempts): $e',
              );
            }
          }

          if (!success) {
            if (attempts < maxRetriesPerItem) {
              await Future.delayed(currentBackoff);
              // Exponential backoff
              currentBackoff = Duration(
                milliseconds: (currentBackoff.inMilliseconds * 2).clamp(
                  initialBackoff.inMilliseconds,
                  maxBackoff.inMilliseconds,
                ),
              );
            }
          }
        }

        if (success) {
          successCount++;
          remainingList.removeAt(0);
          await prefs.setStringList(queueKey, remainingList);
        } else {
          // Stop draining if we hit persistent network/server failure to preserve FIFO order
          break;
        }
      }

      return successCount;
    } finally {
      _isDraining = false;
    }
  }

  /// Default mutation executor against Supabase.
  Future<bool> _defaultExecutor(Map<String, dynamic> mutation) async {
    final table = mutation['table'] as String?;
    final action = mutation['action'] as String? ?? 'insert';
    final payload = mutation['payload'] as Map<String, dynamic>? ?? {};
    final primaryKey = mutation['primary_key'] as String? ?? 'id';
    final id = mutation['target_id'] ?? payload[primaryKey];

    if (table == null || table.isEmpty) {
      return true; // Drop invalid mutation
    }

    try {
      final client = SupabaseClientService.client;
      switch (action.toLowerCase()) {
        case 'insert':
          await client.from(table).insert(payload);
          return true;
        case 'upsert':
          await client.from(table).upsert(payload);
          return true;
        case 'update':
          if (id != null) {
            await client.from(table).update(payload).eq(primaryKey, id);
            return true;
          }
          return false;
        case 'delete':
          if (id != null) {
            await client.from(table).delete().eq(primaryKey, id);
            return true;
          }
          return false;
        default:
          await client.from(table).insert(payload);
          return true;
      }
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OfflineSyncService._defaultExecutor error: $e');
      }
      // Non-network exceptions might be schema or constraint errors
      return false;
    }
  }
}
