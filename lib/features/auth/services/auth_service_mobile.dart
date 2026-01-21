import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/auth_config.dart';
import 'auth_service.dart';

final _appAuth = const FlutterAppAuth();
final _secureStorage = const FlutterSecureStorage();

/// Mobile sign in using flutter_appauth
Future<AuthResult> signIn() async {
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
      return AuthResult(
        success: true,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    } else {
      return AuthResult(success: false, error: 'Authentication failed.');
    }
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }
}

/// Get stored tokens from secure storage
Future<Map<String, String?>> getStoredTokens() async {
  return {
    'access_token': await _secureStorage.read(key: 'access_token'),
    'refresh_token': await _secureStorage.read(key: 'refresh_token'),
    'id_token': await _secureStorage.read(key: 'id_token'),
  };
}

/// Store tokens in secure storage
Future<void> storeTokens({
  String? accessToken,
  String? refreshToken,
  String? idToken,
}) async {
  if (accessToken != null) {
    await _secureStorage.write(key: 'access_token', value: accessToken);
  }
  if (refreshToken != null) {
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }
  if (idToken != null) {
    await _secureStorage.write(key: 'id_token', value: idToken);
  }
}

/// Clear tokens from secure storage
Future<void> clearTokens() async {
  await _secureStorage.delete(key: 'access_token');
  await _secureStorage.delete(key: 'refresh_token');
  await _secureStorage.delete(key: 'id_token');
}

/// Refresh access token
Future<AuthResult> refreshToken(String refreshTokenValue) async {
  try {
    final result = await _appAuth.token(
      TokenRequest(
        AuthConfig.clientId,
        AuthConfig.redirectUri,
        issuer: 'https://${AuthConfig.issuer}',
        refreshToken: refreshTokenValue,
        scopes: AuthConfig.scopes,
      ),
    );

    if (result != null) {
      return AuthResult(
        success: true,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    }
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }

  return AuthResult(success: false, error: 'Token refresh failed.');
}

/// Handle web callback (not used on mobile, always returns null)
Future<AuthResult?> handleWebCallback() async {
  return null;
}
