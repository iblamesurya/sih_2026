import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central BaaS Supabase Client Configuration & Accessor.
///
/// Configured via compile-time `--dart-define` constants:
/// - `SUPABASE_URL`
/// - `SUPABASE_ANON_KEY`
class SupabaseClientService {
  SupabaseClientService._();

  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_key',
  );

  static SupabaseClient? _customClient;
  static bool _isInitialized = false;

  /// Initialize Supabase for the application lifecycle.
  static Future<void> initialize({
    String? url,
    String? anonKey,
    SupabaseClient? customClient,
  }) async {
    if (customClient != null) {
      _customClient = customClient;
      _isInitialized = true;
      return;
    }

    final targetUrl = url ?? defaultUrl;
    final targetAnonKey = anonKey ?? defaultAnonKey;

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: targetUrl,
        // ignore: deprecated_member_use
        anonKey: targetAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
    } catch (e) {
      // In testing or disconnected environments, gracefully store configuration
      if (kDebugMode) {
        debugPrint('Supabase initialization notice: $e');
      }
    }
  }

  /// Sets a custom or mock client for unit/integration testing.
  @visibleForTesting
  static void setMockClient(SupabaseClient? mockClient) {
    _customClient = mockClient;
    _isInitialized = mockClient != null;
  }

  /// Resets the client state.
  @visibleForTesting
  static void reset() {
    _customClient = null;
    _isInitialized = false;
  }

  /// Returns the active SupabaseClient instance.
  static SupabaseClient get client {
    if (_customClient != null) {
      return _customClient!;
    }
    return Supabase.instance.client;
  }

  /// Whether the Supabase client is initialized.
  static bool get isInitialized => _isInitialized || _customClient != null;

  /// Quick accessor to GoTrue Auth.
  static GoTrueClient get auth => client.auth;

  /// Quick accessor for Postgrest query builder.
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Quick accessor for Supabase Storage.
  static SupabaseStorageClient get storage => client.storage;

  /// Quick accessor for Supabase Edge Functions.
  static FunctionsClient get functions => client.functions;

  /// Quick accessor for Supabase RPC functions.
  static PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
  }) =>
      client.rpc<T>(fn, params: params);
}
