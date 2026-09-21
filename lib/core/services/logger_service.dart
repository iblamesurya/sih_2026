import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized application logger providing structured, leveled telemetry.
/// In debug mode, logs are formatted with ISO-8601 timestamps and tags.
/// In release mode, non-fatal logs are filtered to minimize overhead.
class LoggerService {
  LoggerService._();

  static void debug(String message, {String tag = 'APP', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  static void info(String message, {String tag = 'APP'}) {
    _log('INFO', message, tag: tag);
  }

  static void warning(String message, {String tag = 'APP', Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final formatted = '[$timestamp][$level][$tag] $message';

    if (kDebugMode) {
      debugPrint(formatted);
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
    }

    developer.log(
      message,
      time: DateTime.now(),
      name: tag,
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}
