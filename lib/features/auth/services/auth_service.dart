import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/auth_config.dart';

/// Authentication Service
/// 
/// Handles AWS Cognito OAuth PKCE flow with Google.
class AuthService extends ChangeNotifier {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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

  /// Initialize - check for existing tokens
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      _accessToken = await _secureStorage.read(key: 'access_token');
      _refreshToken = await _secureStorage.read(key: 'refresh_token');
      _idToken = await _secureStorage.read(key: 'id_token');

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
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUri,
          issuer: 'https://${AuthConfig.issuer}',
          scopes: AuthConfig.scopes,
          promptValues: ['login'],
          additionalParameters: {
            'identity_provider': 'Google',
          },
        ),
      );

      if (result != null) {
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _idToken = result.idToken;

        // Store tokens securely
        await _secureStorage.write(key: 'access_token', value: _accessToken);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
        await _secureStorage.write(key: 'id_token', value: _idToken);

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Authentication failed. Please try again.';
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
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'id_token');

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
      final result = await _appAuth.token(
        TokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUri,
          issuer: 'https://${AuthConfig.issuer}',
          refreshToken: _refreshToken,
          scopes: AuthConfig.scopes,
        ),
      );

      if (result != null) {
        _accessToken = result.accessToken;
        if (result.refreshToken != null) {
          _refreshToken = result.refreshToken;
        }
        _idToken = result.idToken;

        await _secureStorage.write(key: 'access_token', value: _accessToken);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
        await _secureStorage.write(key: 'id_token', value: _idToken);

        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }

    return false;
  }
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}
