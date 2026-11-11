import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Status of an outbox mutation in the offline synchronization pipeline.
enum SyncStatus {
  pending,
  syncing,
  failedPermanent,
}

/// Structured Outbox Mutation representation with idempotency key and optimistic concurrency metadata.
@immutable
class OutboxMutation {
  final String id;
  final String idempotencyKey;
  final String table;
  final String operation; // 'INSERT', 'UPDATE', 'DELETE'
  final Map<String, dynamic> payload;
  final int baseVersion;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;
  final String? lastError;

  const OutboxMutation({
    required this.id,
    required this.idempotencyKey,
    required this.table,
    required this.operation,
    required this.payload,
    this.baseVersion = 1,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.lastError,
  });

  OutboxMutation copyWith({
    String? id,
    String? idempotencyKey,
    String? table,
    String? operation,
    Map<String, dynamic>? payload,
    int? baseVersion,
    DateTime? createdAt,
    int? retryCount,
    SyncStatus? status,
    String? lastError,
  }) {
    return OutboxMutation(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      table: table ?? this.table,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotency_key': idempotencyKey,
        'idempotencyKey': idempotencyKey,
        'table': table,
        'operation': operation,
        'action': operation.toLowerCase(),
        'payload': payload,
        'base_version': baseVersion,
        'baseVersion': baseVersion,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'retryCount': retryCount,
        'status': status.name,
        if (lastError != null) 'last_error': lastError,
      };

  factory OutboxMutation.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase();
    SyncStatus parsedStatus = SyncStatus.pending;
    if (statusStr == SyncStatus.syncing.name) {
      parsedStatus = SyncStatus.syncing;
    } else if (statusStr == SyncStatus.failedPermanent.name ||
        statusStr == 'failed_permanent' ||
        statusStr == 'dead_letter') {
      parsedStatus = SyncStatus.failedPermanent;
    }

    final id = (json['id'] ?? 'mut_${DateTime.now().microsecondsSinceEpoch}').toString();
    final idemKey = (json['idempotency_key'] ?? json['idempotencyKey'] ?? id).toString();
    final table = (json['table'] ?? '').toString();
    final op = (json['operation'] ?? json['action'] ?? 'INSERT').toString().toUpperCase();
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};
    final baseVersion = (json['base_version'] ?? json['baseVersion'] as num?)?.toInt() ?? 1;
    final createdAt = DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now().toUtc();
    final retries = (json['retry_count'] ?? json['retryCount'] as num?)?.toInt() ?? 0;
    final lastErr = json['last_error']?.toString();

    return OutboxMutation(
      id: id,
      idempotencyKey: idemKey,
      table: table,
      operation: op,
      payload: payload,
      baseVersion: baseVersion,
      createdAt: createdAt,
      retryCount: retries,
      status: parsedStatus,
      lastError: lastErr,
    );
  }
}

/// Backwards compatibility alias for existing code referencing `OfflineMutation`.
typedef OfflineMutation = OutboxMutation;

/// Exception indicating a permanent client, validation, or schema rejection
/// that should be quarantined to prevent head-of-line blocking.
class PermanentSyncException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const PermanentSyncException(this.message, {this.code, this.details});

  @override
  String toString() => 'PermanentSyncException: $message (code: $code)';
}

/// Offline Synchronization Service managing a strictly FIFO mutation queue
/// persisted in [SharedPreferences] with a hard capacity of 100 items,
/// deterministic UUID idempotency keys, head-of-line unblocking dead-letter quarantine,
/// and exponential backoff with random jitter.
class OfflineSyncService {
  static const String queueKey = 'offline_queue';
  static const String deadLetterKey = 'offline_dead_letter_queue';
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

  /// Acquires the queue mutex lock to prevent concurrent modifications between
  /// in-flight enqueue operations and queue drain / removal operations.
  Future<T> _withQueueLock<T>(Future<T> Function() action) async {
    final previousLock = _enqueueLock;
    final completer = Completer<void>();
    _enqueueLock = completer.future;

    if (previousLock != null) {
      try {
        await previousLock;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      completer.complete();
    }
  }

  /// Generates a valid standard UUID v4 string (8-4-4-4-12 hex).
  static String generateUuid([String? seed]) {
    final rawBytes = seed != null
        ? md5.convert(utf8.encode(seed)).bytes
        : md5
            .convert(utf8.encode(
                '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextDouble()}'))
            .bytes;
    final hexStr =
        rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hexStr.substring(0, 8)}-'
        '${hexStr.substring(8, 12)}-'
        '4${hexStr.substring(13, 16)}-'
        'a${hexStr.substring(17, 20)}-'
        '${hexStr.substring(20, 32)}';
  }

  /// Determines if an exception represents a permanent client-side or schema error
  /// ('23503', '22P02', '42501', 'P0002', HTTP 4xx) that should be quarantined
  /// to eliminate head-of-line blocking.
  static bool isPermanentError(dynamic error) {
    if (error == null) return false;
    if (error is PermanentSyncException) return true;

    final errStr = error.toString().toLowerCase();

    // Check PostgrestException codes
    if (error is PostgrestException) {
      final code = (error.code ?? '').toUpperCase();
      if (code == '23503' || // Foreign key violation
          code == '22P02' || // Invalid text representation (UUID)
          code == '42501' || // Insufficient privileges / RLS violation
          code == 'P0002') { // Optimistic concurrency version mismatch
        return true;
      }
      if (code.startsWith('4')) {
        return true; // 4xx client errors
      }
    }

    // String patterns for PostgreSQL codes & HTTP 4xx
    const permanentCodes = ['23503', '22p02', '42501', 'p0002'];
    for (final code in permanentCodes) {
      if (errStr.contains(code)) return true;
    }

    final permanentPatterns = [
      'permanent',
      'dead_letter',
      'foreign key',
      'foreign_key',
      'violates foreign key',
      'permission denied',
      'row-level security',
      'version mismatch',
      '400 bad request',
      '401 unauthorized',
      '403 forbidden',
      '404 not found',
      '409 conflict',
      '422 unprocessable',
      'status: 4',
      'statuscode: 4',
    ];

    for (final pattern in permanentPatterns) {
      if (errStr.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Adds a mutation to the offline queue with strict FIFO ordering and deterministic idempotency metadata.
  Future<void> enqueue(Map<String, dynamic> mutation) async {
    await _withQueueLock(() async {
      final prefs = await _prefs;
      final currentList = prefs.getStringList(queueKey) ?? [];

      // Create a mutable copy of the mutation with metadata
      final enrichedMutation = Map<String, dynamic>.from(mutation);
      enrichedMutation.putIfAbsent(
        'id',
        () => 'mut_${DateTime.now().microsecondsSinceEpoch}',
      );

      final seed =
          '${enrichedMutation['id']}_${enrichedMutation['table']}_${enrichedMutation['created_at']}';
      final idemKey = enrichedMutation['idempotency_key'] ??
          enrichedMutation['idempotencyKey'] ??
          generateUuid(seed);

      enrichedMutation.putIfAbsent('idempotency_key', () => idemKey);
      enrichedMutation.putIfAbsent('idempotencyKey', () => idemKey);
      enrichedMutation.putIfAbsent(
        'operation',
        () => (enrichedMutation['action'] ?? 'INSERT').toString().toUpperCase(),
      );
      enrichedMutation.putIfAbsent(
        'base_version',
        () => enrichedMutation['baseVersion'] ?? 1,
      );
      enrichedMutation.putIfAbsent(
        'created_at',
        () => DateTime.now().toUtc().toIso8601String(),
      );
      enrichedMutation.putIfAbsent('status', () => SyncStatus.pending.name);
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
          'OfflineSyncService: Enqueued mutation ${enrichedMutation['id']} (idempotencyKey: $idemKey). Queue size: ${updatedList.length}',
        );
      }
    });
  }

  /// Enqueues a strongly-typed [OutboxMutation].
  Future<void> enqueueMutation(OutboxMutation mutation) async {
    await enqueue(mutation.toJson());
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

  /// Retrieves typed [OutboxMutation] representations of pending items.
  Future<List<OutboxMutation>> getOutboxQueue() async {
    final rawQueue = await getQueue();
    return rawQueue.map((json) => OutboxMutation.fromJson(json)).toList();
  }

  /// Retrieves quarantined mutations that failed permanently (dead-letter queue).
  Future<List<Map<String, dynamic>>> getDeadLetterQueue() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(deadLetterKey) ?? [];
    final List<Map<String, dynamic>> queue = [];

    for (final raw in list) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          queue.add(decoded);
        } else if (decoded is Map) {
          queue.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    return queue;
  }

  /// Returns the current number of pending items in the active queue.
  Future<int> get queueLength async {
    final prefs = await _prefs;
    return (prefs.getStringList(queueKey) ?? []).length;
  }

  /// Alias method for getting the queue length.
  Future<int> getQueueLength() => queueLength;

  /// Returns the count of quarantined permanent failures.
  Future<int> get deadLetterQueueLength async {
    final prefs = await _prefs;
    return (prefs.getStringList(deadLetterKey) ?? []).length;
  }

  /// Clears all pending mutations from active storage.
  Future<void> clearQueue() async {
    await _withQueueLock(() async {
      final prefs = await _prefs;
      await prefs.remove(queueKey);
    });
  }

  /// Clears the dead-letter quarantine queue.
  Future<void> clearDeadLetterQueue() async {
    final prefs = await _prefs;
    await prefs.remove(deadLetterKey);
  }

  /// Returns a set of entity IDs that currently have pending, uncommitted mutations in the outbox queue.
  /// Used by [DataHydrationService] to prevent clean remote queries from overwriting local uncommitted edits.
  Future<Set<String>> getDirtyEntityIds() async {
    final queue = await getQueue();
    final dirty = <String>{};

    for (final mutation in queue) {
      final targetId = mutation['target_id']?.toString();
      if (targetId != null && targetId.isNotEmpty) {
        dirty.add(targetId);
      }

      final payload = mutation['payload'];
      if (payload is Map) {
        final id = payload['id']?.toString();
        if (id != null && id.isNotEmpty) {
          dirty.add(id);
        }
      }

      for (final key in [
        'pond_data',
        'log_data',
        'feed_data',
        'scan_data',
        'expense_data',
        'harvest_data'
      ]) {
        final sub = mutation[key];
        if (sub is Map) {
          final id = sub['id']?.toString();
          if (id != null && id.isNotEmpty) {
            dirty.add(id);
          }
        }
      }
    }

    return dirty;
  }

  /// Atomically removes a mutation from the persistent queue by reading
  /// the fresh queue from [SharedPreferences] under the [_enqueueLock] mutex.
  /// This prevents in-flight mutations added by [enqueue] from being clobbered.
  Future<void> _atomicRemoveFromQueue(String mutationId) async {
    await _withQueueLock(() async {
      final prefs = await _prefs;
      final currentList = prefs.getStringList(queueKey) ?? [];
      if (currentList.isEmpty) return;

      final updatedList = <String>[];
      bool removed = false;

      for (final raw in currentList) {
        if (!removed) {
          try {
            final decoded = jsonDecode(raw);
            final id = (decoded is Map ? decoded['id'] : null)?.toString();
            if (id == mutationId) {
              removed = true;
              continue; // Do not include in updated list
            }
          } catch (_) {}
        }
        updatedList.add(raw);
      }

      // If not removed by matching ID, remove the head item as a fallback
      if (!removed && updatedList.isNotEmpty) {
        updatedList.removeAt(0);
      }

      await prefs.setStringList(queueKey, updatedList);
    });
  }

  @visibleForTesting
  Future<void> atomicRemoveFromQueue(String mutationId) =>
      _atomicRemoveFromQueue(mutationId);

  static bool _isPondInsert(Map<String, dynamic> mutation) {
    final table = (mutation['table'] ?? '').toString().toLowerCase();
    final op = (mutation['operation'] ??
            mutation['action'] ??
            mutation['type'] ??
            '')
        .toString()
        .toUpperCase();
    if (table == 'ponds') {
      return op == 'INSERT' || op == 'UPSERT';
    }
    return op == 'INSERT_POND';
  }

  static String? _extractPondIdFromParent(Map<String, dynamic> mutation) {
    final payload = mutation['payload'] is Map
        ? (mutation['payload'] as Map)
        : mutation;
    final pondData =
        mutation['pond_data'] is Map ? (mutation['pond_data'] as Map) : null;
    final id = payload['id'] ??
        payload['pond_id'] ??
        payload['pondId'] ??
        pondData?['id'] ??
        pondData?['pond_id'] ??
        pondData?['pondId'] ??
        mutation['target_id'];
    return id?.toString();
  }

  static bool _isChildOfPond(Map<String, dynamic> mutation, String parentId) {
    if (parentId.isEmpty) return false;
    final payload =
        mutation['payload'] is Map ? (mutation['payload'] as Map) : null;
    final logData =
        mutation['log_data'] is Map ? (mutation['log_data'] as Map) : null;
    final feedData =
        mutation['feed_data'] is Map ? (mutation['feed_data'] as Map) : null;
    final scanData =
        mutation['scan_data'] is Map ? (mutation['scan_data'] as Map) : null;
    final expenseData = mutation['expense_data'] is Map
        ? (mutation['expense_data'] as Map)
        : null;
    final harvestData = mutation['harvest_data'] is Map
        ? (mutation['harvest_data'] as Map)
        : null;

    final candidates = [
      payload?['pond_id'],
      payload?['pondId'],
      mutation['pond_id'],
      mutation['pondId'],
      logData?['pond_id'],
      logData?['pondId'],
      feedData?['pond_id'],
      feedData?['pondId'],
      scanData?['pond_id'],
      scanData?['pondId'],
      expenseData?['pond_id'],
      expenseData?['pondId'],
      harvestData?['pond_id'],
      harvestData?['pondId'],
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.toString() == parentId) {
        return true;
      }
    }
    return false;
  }

  /// Quarantines a permanently failed mutation to the dead-letter queue under the [_enqueueLock] mutex.
  /// If the failed mutation was an offline pond creation (`INSERT` / `UPSERT` on `ponds`),
  /// this cascades to automatically quarantine all dependent child mutations referencing
  /// the failed pond ID (`parentId`) to prevent false foreign key (23503) errors.
  Future<void> _quarantineMutationAndChildren(
    Map<String, dynamic> mutation,
    String? failureReason,
  ) async {
    await _withQueueLock(() async {
      final prefs = await _prefs;
      final currentQueue = prefs.getStringList(queueKey) ?? [];
      final currentDeadLetter = prefs.getStringList(deadLetterKey) ?? [];

      final mutationId = mutation['id']?.toString();
      final isPond = _isPondInsert(mutation);
      final parentId = isPond ? _extractPondIdFromParent(mutation) : null;

      final parentQuarantined = Map<String, dynamic>.from(mutation);
      parentQuarantined['status'] = SyncStatus.failedPermanent.name;
      parentQuarantined['last_error'] = failureReason;
      parentQuarantined['lastError'] = failureReason;

      final itemsToQuarantine = <Map<String, dynamic>>[parentQuarantined];
      final remainingQueue = <String>[];

      bool parentRemoved = false;

      for (final raw in currentQueue) {
        Map<String, dynamic> item;
        try {
          final decoded = jsonDecode(raw);
          item = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded as Map);
        } catch (_) {
          continue;
        }

        final itemId = item['id']?.toString();

        if (!parentRemoved &&
            (itemId == mutationId || (mutationId == null && itemId == null))) {
          parentRemoved = true;
          continue; // Parent is already in itemsToQuarantine
        }

        if (parentId != null &&
            parentId.isNotEmpty &&
            _isChildOfPond(item, parentId)) {
          final childQuarantined = Map<String, dynamic>.from(item);
          childQuarantined['status'] = SyncStatus.failedPermanent.name;
          final errorMsg = 'Blocked by failed parent pond creation: $parentId';
          childQuarantined['last_error'] = errorMsg;
          childQuarantined['lastError'] = errorMsg;
          itemsToQuarantine.add(childQuarantined);

          if (kDebugMode) {
            debugPrint(
              'OfflineSyncService: Cascading quarantine: child mutation ${childQuarantined['id']} '
              'blocked by failed parent pond $parentId',
            );
          }
          continue;
        }

        remainingQueue.add(raw);
      }

      if (!parentRemoved &&
          remainingQueue.isNotEmpty &&
          (mutationId == null || mutationId.isEmpty)) {
        remainingQueue.removeAt(0);
      }

      final updatedDeadLetter = List<String>.from(currentDeadLetter);
      for (final qItem in itemsToQuarantine) {
        while (updatedDeadLetter.length >= maxQueueCapacity) {
          updatedDeadLetter.removeAt(0);
        }
        updatedDeadLetter.add(jsonEncode(qItem));
      }

      await prefs.setStringList(deadLetterKey, updatedDeadLetter);
      await prefs.setStringList(queueKey, remainingQueue);

      if (kDebugMode) {
        debugPrint(
          'OfflineSyncService: Quarantined ${itemsToQuarantine.length} mutation(s) '
          '(parent: $mutationId, reason: $failureReason). Remaining queue size: ${remainingQueue.length}',
        );
      }
    });
  }

  @visibleForTesting
  Future<void> quarantineMutationAndChildren(
    Map<String, dynamic> mutation,
    String? failureReason,
  ) =>
      _quarantineMutationAndChildren(mutation, failureReason);

  /// Sequentially drains all pending mutations with:
  /// 1. Re-entrancy protection.
  /// 2. Head-of-line unblocking (permanent errors quarantined to dead-letter storage).
  /// 3. Exponential backoff with random jitter on transient network/server failures.
  Future<int> drainQueue({
    Future<bool> Function(Map<String, dynamic> mutation)? executor,
    int maxRetriesPerItem = 3,
    Duration initialBackoff = const Duration(milliseconds: 200),
    Duration maxBackoff = const Duration(seconds: 4),
    bool useJitter = true,
  }) async {
    if (_isDraining && _activeDrainFuture != null) {
      return _activeDrainFuture!;
    }

    final future = _internalDrain(
      executor: executor,
      maxRetriesPerItem: maxRetriesPerItem,
      initialBackoff: initialBackoff,
      maxBackoff: maxBackoff,
      useJitter: useJitter,
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
    bool useJitter = true,
  }) async {
    _isDraining = true;
    try {
      int successCount = 0;

      while (true) {
        Map<String, dynamic>? currentMutation;

        await _withQueueLock(() async {
          final prefs = await _prefs;
          final currentList = prefs.getStringList(queueKey) ?? [];
          while (currentList.isNotEmpty) {
            try {
              final decoded = jsonDecode(currentList.first);
              currentMutation = decoded is Map<String, dynamic>
                  ? decoded
                  : Map<String, dynamic>.from(decoded as Map);
              break;
            } catch (e) {
              // Corrupted item, discard
              currentList.removeAt(0);
              await prefs.setStringList(queueKey, currentList);
            }
          }
        });

        if (currentMutation == null) {
          // Active queue is completely drained
          break;
        }

        final mutation = currentMutation!;
        final mutationId = (mutation['id'] ?? '').toString();

        int attempts = (mutation['retry_count'] as num?)?.toInt() ?? 0;
        bool success = false;
        bool isPermanent = false;
        String? failureReason;
        Duration currentBackoff = initialBackoff;

        while (attempts < maxRetriesPerItem && !success && !isPermanent) {
          attempts++;
          mutation['retry_count'] = attempts;
          mutation['status'] = SyncStatus.syncing.name;
          try {
            if (executor != null) {
              success = await executor(mutation);
            } else {
              success = await _defaultExecutor(mutation);
            }
          } catch (e) {
            failureReason = e.toString();
            if (isPermanentError(e)) {
              isPermanent = true;
              success = false;
              break; // Do not retry permanent client/schema errors!
            } else {
              success = false;
              if (kDebugMode) {
                debugPrint(
                  'OfflineSyncService: Error draining item $mutationId (attempt $attempts): $e',
                );
              }
            }
          }

          if (!success && !isPermanent) {
            if (attempts < maxRetriesPerItem) {
              // Exponential backoff + random jitter formula: min(30000, pow(2, retry) * 500) + rand(250)
              final baseMs = currentBackoff.inMilliseconds > 50
                  ? math.min(30000, (math.pow(2, attempts) * 500).toInt())
                  : (currentBackoff.inMilliseconds * 2);
              final jitter =
                  useJitter && baseMs > 10 ? math.Random().nextInt(250) : 0;
              final delayMs = math.min(30000, baseMs + jitter);
              await Future.delayed(Duration(milliseconds: delayMs));

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
          await _atomicRemoveFromQueue(mutationId);
        } else if (isPermanent) {
          // Cascading parent-child quarantine for failed parent pond creation
          // and eliminate head-of-line blocking
          await _quarantineMutationAndChildren(mutation, failureReason);
          // Continue to process subsequent unblocked mutations
          continue;
        } else {
          // Transient network/server failure: update retry count and break to preserve FIFO
          await _withQueueLock(() async {
            final prefs = await _prefs;
            final currentList = prefs.getStringList(queueKey) ?? [];
            if (currentList.isNotEmpty) {
              final updated = List<String>.from(currentList);
              for (int i = 0; i < updated.length; i++) {
                try {
                  final dec = jsonDecode(updated[i]) as Map;
                  if (dec['id']?.toString() == mutationId) {
                    final m = Map<String, dynamic>.from(dec);
                    m['retry_count'] = attempts;
                    m['status'] = SyncStatus.pending.name;
                    updated[i] = jsonEncode(m);
                    break;
                  }
                } catch (_) {}
              }
              await prefs.setStringList(queueKey, updated);
            }
          });
          break;
        }
      }

      return successCount;
    } finally {
      _isDraining = false;
    }
  }

  /// Default mutation executor against Supabase.
  /// Dispatches via `apply_idempotent_mutation` RPC if available, with direct table fallback.
  Future<bool> _defaultExecutor(Map<String, dynamic> mutation) async {
    String? table = mutation['table'] as String?;
    String action = mutation['action'] as String? ?? 'insert';
    Map<String, dynamic> payload = (mutation['payload'] is Map)
        ? Map<String, dynamic>.from(mutation['payload'] as Map)
        : {};

    // Support legacy typed UI mutation envelopes seamlessly
    if (table == null || table.isEmpty) {
      final type = (mutation['type'] as String? ?? '').toUpperCase();
      switch (type) {
        case 'INSERT_WATER_LOG':
          table = 'water_logs';
          payload =
              Map<String, dynamic>.from((mutation['log_data'] as Map?) ?? {});
          break;
        case 'INSERT_FEED_PLAN':
          table = 'feed_logs';
          payload =
              Map<String, dynamic>.from((mutation['feed_data'] as Map?) ?? {});
          break;
        case 'INSERT_POND':
          table = 'ponds';
          payload =
              Map<String, dynamic>.from((mutation['pond_data'] as Map?) ?? {});
          break;
        case 'INSERT_DISEASE_SCAN':
          table = 'disease_scans';
          payload =
              Map<String, dynamic>.from((mutation['scan_data'] as Map?) ?? {});
          break;
        case 'INSERT_EXPENSE':
          table = 'expenses';
          payload =
              Map<String, dynamic>.from((mutation['expense_data'] as Map?) ?? {});
          break;
        case 'INSERT_HARVEST':
          table = 'harvests';
          payload =
              Map<String, dynamic>.from((mutation['harvest_data'] as Map?) ?? {});
          break;
      }
    }

    final primaryKey = mutation['primary_key'] as String? ?? 'id';
    final id = mutation['target_id'] ?? payload[primaryKey];

    if (table == null || table.isEmpty) {
      return true; // Drop invalid mutation
    }

    try {
      final client = SupabaseClientService.client;

      // 1. Try apply_idempotent_mutation RPC first if configured
      bool rpcHandled = false;
      try {
        final idempotencyKey = mutation['idempotency_key'] ??
            mutation['idempotencyKey'] ??
            generateUuid();
        final baseVersion = (mutation['base_version'] ??
            mutation['baseVersion'] ??
            1) as int;

        final rpcResult = await client.rpc(
          'apply_idempotent_mutation',
          params: {
            'p_idempotency_key': idempotencyKey,
            'p_table_name': table,
            'p_operation': action.toUpperCase(),
            'p_payload': payload,
            'p_base_version': baseVersion,
          },
        );
        if (rpcResult != null) {
          rpcHandled = true;
          return true;
        }
      } catch (rpcErr) {
        if (isPermanentError(rpcErr)) {
          rethrow; // Propagate permanent client error (e.g. code P0002, 23503, 42501)
        }
        // If function does not exist, fall through to direct table operation
      }

      // 2. Direct table fallback if RPC is not available
      if (!rpcHandled) {
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
      }
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      if (isPermanentError(e)) {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('OfflineSyncService._defaultExecutor error: $e');
      }
      return false;
    }
  }
}
