import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Authentication Service managing Phone OTP authentication mapped to
/// Supabase Auth with `<normalized_phone>@prawnguard.app` emails.
class AuthService {
  final SupabaseClient? _injectedClient;

  AuthService([this._injectedClient]);

  SupabaseClient get _client {
    final injected = _injectedClient;
    if (injected != null) {
      return injected;
    }
    return SupabaseClientService.client;
  }

  GoTrueClient get _auth => _client.auth;

  /// Domain suffix used for mapping phone numbers to Supabase email auth.
  static const String emailDomain = 'prawnguard.app';

  /// Normalizes an Indian phone number to standard 10 digits.
  ///
  /// Supports:
  /// - +91 98765 43210 -> 9876543210
  /// - +919876543210 -> 9876543210
  /// - 09876543210 -> 9876543210
  /// - 9876543210 -> 9876543210
  ///
  /// Throws [ArgumentError] if the input cannot be resolved to a valid
  /// 10-digit Indian mobile number.
  static String normalizePhone(String rawPhone) {
    if (rawPhone.trim().isEmpty) {
      throw ArgumentError('Phone number cannot be empty.');
    }

    // Strip all non-digit characters except leading plus
    String cleaned = rawPhone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Handle leading +91
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // If starts with 91 and total length is 12 digits
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    // If starts with 0 and total length is 11 digits
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }

    // Validate remaining string is exactly 10 digits
    final tenDigitRegex = RegExp(r'^[6-9]\d{9}$');
    if (!tenDigitRegex.hasMatch(cleaned)) {
      final fallbackTenDigit = RegExp(r'^\d{10}$');
      if (!fallbackTenDigit.hasMatch(cleaned)) {
        throw ArgumentError(
          'Invalid phone number: "$rawPhone". Expected 10-digit Indian phone number.',
        );
      }
    }

    return cleaned;
  }

  /// Maps a raw or formatted phone number to its corresponding Supabase email.
  static String phoneToEmail(String phone) {
    final normalized = normalizePhone(phone);
    return '$normalized@$emailDomain';
  }

  /// Initiates passwordless OTP authentication for the specified Indian phone.
  Future<void> signInWithOtp(String phone) async {
    final email = phoneToEmail(phone);
    try {
      await _auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.prawnguard://login-callback',
        shouldCreateUser: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.signInWithOtp error: $e');
      }
      rethrow;
    }
  }

  /// Verifies the OTP token received by the farmer.
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    final email = phoneToEmail(phone);
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      throw ArgumentError('OTP token cannot be empty.');
    }

    try {
      final response = await _auth.verifyOTP(
        email: email,
        token: cleanToken,
        type: OtpType.email,
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.verifyOtp error: $e');
      }
      rethrow;
    }
  }

  /// Signs out the current user from Supabase.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.signOut error: $e');
      }
      rethrow;
    }
  }

  /// Returns the currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Returns the current active session, or null.
  Session? get currentSession => _auth.currentSession;

  /// Returns whether a user session is active.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
