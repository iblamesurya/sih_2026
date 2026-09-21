import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_sync_service.dart';

/// Exception thrown when a mutation is safely queued for offline execution.
class OfflineQueuedException implements Exception {
  final String message;
  final Map<String, dynamic> queuedMutation;

  const OfflineQueuedException({
    this.message = 'Network unavailable; mutation queued for offline sync.',
    required this.queuedMutation,
  });

  @override
  String toString() => 'OfflineQueuedException: $message ($queuedMutation)';
}

/// Base Repository class providing robust network mutation wrapping with
/// automatic offline fallback and queuing via [OfflineSyncService].
abstract class BaseRepository {
  final OfflineSyncService _offlineSyncService;

  BaseRepository([OfflineSyncService? offlineSyncService])
      : _offlineSyncService = offlineSyncService ?? OfflineSyncService();

  OfflineSyncService get offlineSyncService => _offlineSyncService;

  /// Executes [networkAction] safely. If a network connectivity failure,
  /// timeout, or client exception occurs, the [offlineMutation] is automatically
  /// enqueued into the local offline queue and [fallbackValue] is returned.
  ///
  /// If [fallbackValue] is omitted and [rethrowIfNoFallback] is true,
  /// an [OfflineQueuedException] is thrown.
  Future<T?> safeMutate<T>({
    required Future<T> Function() networkAction,
    required Map<String, dynamic> offlineMutation,
    T? fallbackValue,
    bool rethrowIfNoFallback = false,
  }) async {
    try {
      final result = await networkAction();
      return result;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('BaseRepository: SocketException detected ($e). Queuing offline mutation.');
      }
      await _offlineSyncService.enqueue(offlineMutation);
      if (fallbackValue != null) return fallbackValue;
      if (rethrowIfNoFallback) {
        throw OfflineQueuedException(
          message: 'SocketException: Network unreachable.',
          queuedMutation: offlineMutation,
        );
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('BaseRepository: TimeoutException detected ($e). Queuing offline mutation.');
      }
      await _offlineSyncService.enqueue(offlineMutation);
      if (fallbackValue != null) return fallbackValue;
      if (rethrowIfNoFallback) {
        throw OfflineQueuedException(
          message: 'TimeoutException: Request timed out.',
          queuedMutation: offlineMutation,
        );
      }
      return null;
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('BaseRepository: http.ClientException detected ($e). Queuing offline mutation.');
      }
      await _offlineSyncService.enqueue(offlineMutation);
      if (fallbackValue != null) return fallbackValue;
      if (rethrowIfNoFallback) {
        throw OfflineQueuedException(
          message: 'ClientException: Network client error.',
          queuedMutation: offlineMutation,
        );
      }
      return null;
    } on PostgrestException catch (e) {
      // Intercept network/offline related Postgrest error codes or messages
      if (_isNetworkRelatedPostgrestError(e)) {
        if (kDebugMode) {
          debugPrint('BaseRepository: Postgrest network error ($e). Queuing offline mutation.');
        }
        await _offlineSyncService.enqueue(offlineMutation);
        if (fallbackValue != null) return fallbackValue;
        if (rethrowIfNoFallback) {
          throw OfflineQueuedException(
            message: 'PostgrestException: ${e.message}',
            queuedMutation: offlineMutation,
          );
        }
        return null;
      }
      rethrow;
    } catch (e) {
      // Check for generic network string matches (e.g. XMLHttpRequest error on web)
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('network') ||
          errStr.contains('timeout') ||
          errStr.contains('connection refused') ||
          errStr.contains('failed to fetch') ||
          errStr.contains('clientexception')) {
        if (kDebugMode) {
          debugPrint('BaseRepository: Generic network error ($e). Queuing offline mutation.');
        }
        await _offlineSyncService.enqueue(offlineMutation);
        if (fallbackValue != null) return fallbackValue;
        if (rethrowIfNoFallback) {
          throw OfflineQueuedException(
            message: 'Network error: $e',
            queuedMutation: offlineMutation,
          );
        }
        return null;
      }
      rethrow;
    }
  }

  bool _isNetworkRelatedPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code?.toLowerCase() ?? '';
    return message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('failed to fetch') ||
        code == '08000' ||
        code == '08003' ||
        code == '08006';
  }

  static final Map<String, _RepositoryCacheEntry> _cache = {};

  /// Retrieves data from in-memory cache if valid and not expired,
  /// otherwise runs [fetcher], caches the result for [ttl], and returns it.
  Future<T> getOrFetch<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh && _cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (now.isBefore(entry.expiresAt) && entry.value is T) {
        return entry.value as T;
      }
    }

    final freshData = await fetcher();
    _cache[key] = _RepositoryCacheEntry(
      value: freshData,
      expiresAt: now.add(ttl),
    );
    return freshData;
  }

  /// Clears cache for a given key, matching prefix, or all entries if omitted.
  static void invalidateCache([String? prefix]) {
    if (prefix == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((k, v) => k.startsWith(prefix));
    }
  }
}

class _RepositoryCacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  const _RepositoryCacheEntry({
    required this.value,
    required this.expiresAt,
  });
}
