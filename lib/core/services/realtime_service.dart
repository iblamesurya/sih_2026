import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Realtime Service managing Supabase Realtime subscriptions and broadcast streams
/// for water logs, feed logs, disease scans, and activity events.
class RealtimeService {
  final SupabaseClient? _injectedClient;

  final StreamController<Map<String, dynamic>> _waterLogsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _feedLogsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _diseaseScansController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _activityEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  RealtimeChannel? _generalChannel;
  final Map<String, RealtimeChannel> _pondChannels = {};

  RealtimeService([this._injectedClient]);

  SupabaseClient get _client {
    final injected = _injectedClient;
    if (injected != null) {
      return injected;
    }
    return SupabaseClientService.client;
  }

  /// Broadcast stream for new or updated water quality logs.
  Stream<Map<String, dynamic>> get waterLogsStream =>
      _waterLogsController.stream;

  /// Broadcast stream for new or updated feed logs.
  Stream<Map<String, dynamic>> get feedLogsStream => _feedLogsController.stream;

  /// Broadcast stream for new disease scan analyses.
  Stream<Map<String, dynamic>> get diseaseScansStream =>
      _diseaseScansController.stream;

  /// Broadcast stream for farm activity events.
  Stream<Map<String, dynamic>> get activityEventsStream =>
      _activityEventsController.stream;

  /// Initializes global realtime channels across the core tables.
  void initializeSubscriptions() {
    try {
      _generalChannel = _client.channel('public:all_tables');

      _generalChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'water_logs',
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              _waterLogsController.add(record);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'feed_logs',
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              _feedLogsController.add(record);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'disease_scans',
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              _diseaseScansController.add(record);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'activity_events',
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              _activityEventsController.add(record);
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RealtimeService.initializeSubscriptions notice: $e');
      }
    }
  }

  /// Subscribes to real-time events for a specific pond ID.
  void subscribeToPond(String pondId) {
    if (_pondChannels.containsKey(pondId)) return;

    try {
      final channel = _client.channel('pond:$pondId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'water_logs',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'pond_id',
              value: pondId,
            ),
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty
                  ? payload.newRecord
                  : payload.oldRecord;
              _waterLogsController.add(record);
            },
          )
          .subscribe();
      _pondChannels[pondId] = channel;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RealtimeService.subscribeToPond error ($pondId): $e');
      }
    }
  }

  /// Unsubscribes from a specific pond's realtime channel.
  void unsubscribeFromPond(String pondId) {
    final channel = _pondChannels.remove(pondId);
    if (channel != null) {
      try {
        _client.removeChannel(channel);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('RealtimeService.unsubscribeFromPond notice: $e');
        }
      }
    }
  }

  /// Emits a mock or offline water log event into the stream (for testing/local updates).
  @visibleForTesting
  void emitWaterLog(Map<String, dynamic> data) =>
      _waterLogsController.add(data);

  /// Emits a mock or offline feed log event into the stream.
  @visibleForTesting
  void emitFeedLog(Map<String, dynamic> data) => _feedLogsController.add(data);

  /// Emits a mock or offline disease scan event into the stream.
  @visibleForTesting
  void emitDiseaseScan(Map<String, dynamic> data) =>
      _diseaseScansController.add(data);

  /// Emits a mock or offline activity event into the stream.
  @visibleForTesting
  void emitActivityEvent(Map<String, dynamic> data) =>
      _activityEventsController.add(data);

  /// Closes and disposes all active channels and controllers.
  void dispose() {
    if (_generalChannel != null) {
      try {
        _client.removeChannel(_generalChannel!);
      } catch (_) {}
    }
    for (final channel in _pondChannels.values) {
      try {
        _client.removeChannel(channel);
      } catch (_) {}
    }
    _pondChannels.clear();
    _waterLogsController.close();
    _feedLogsController.close();
    _diseaseScansController.close();
    _activityEventsController.close();
  }
}
