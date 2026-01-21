import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/auth_config.dart';
import 'auth_service_mobile.dart' if (dart.library.html) 'auth_service_web.dart' as platform;

/// Authentication Service
/// 
/// Handles AWS Cognito OAuth PKCE flow with Google.
/// Supports both mobile (flutter_appauth) and web (URL redirect).
class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  String? _errorMessage;

  AuthState get state => _state;
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _accessToken != null;

  /// Initialize - check for existing tokens or handle OAuth callback
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      // On web, check if this is an OAuth callback
      if (kIsWeb) {
        final result = await platform.handleWebCallback();
        if (result != null) {
          if (result.success) {
            _accessToken = result.accessToken;
            _refreshToken = result.refreshToken;
            _idToken = result.idToken;
            _state = AuthState.authenticated;
          } else {
            _errorMessage = result.error;
            _state = AuthState.error;
          }
          notifyListeners();
          return;
        }
      }

      // Check for stored tokens
      final tokens = await platform.getStoredTokens();
      _accessToken = tokens['access_token'];
      _refreshToken = tokens['refresh_token'];
      _idToken = tokens['id_token'];

      if (_accessToken != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      debugPrint('Auth initialization error: $e');
    }

    notifyListeners();
  }

  /// Sign in with Google via Cognito
  Future<bool> signInWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await platform.signIn();
      
      if (result.success) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _idToken = result.idToken;

        await platform.storeTokens(
          accessToken: _accessToken,
          refreshToken: _refreshToken,
          idToken: _idToken,
        );

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = result.error ?? 'Authentication failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Authentication error: ${e.toString()}';
      debugPrint('Sign in error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await platform.clearTokens();
      _accessToken = null;
      _refreshToken = null;
      _idToken = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      debugPrint('Sign out error: $e');
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// Refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final result = await platform.refreshToken(_refreshToken!);
      
      if (result.success) {
        _accessToken = result.accessToken;
        if (result.refreshToken != null) {
          _refreshToken = result.refreshToken;
        }
        _idToken = result.idToken;

        await platform.storeTokens(
          accessToken: _accessToken,
          refreshToken: _refreshToken,
          idToken: _idToken,
        );

        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }

    return false;
  }
}

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? error;

  AuthResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.error,
  });
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// PKCE Helper functions
String generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}

String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

String generateRandomState() {
  final random = Random.secure();
  final values = List<int>.generate(16, (_) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}
