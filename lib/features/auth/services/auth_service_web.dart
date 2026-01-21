import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../../../core/constants/auth_config.dart';
import 'auth_service.dart';

/// Web sign in using URL redirect to Cognito Hosted UI
Future<AuthResult> signIn() async {
  try {
    // Generate PKCE values
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final state = generateRandomState();

    // Store PKCE values in sessionStorage for the callback
    html.window.sessionStorage['code_verifier'] = codeVerifier;
    html.window.sessionStorage['oauth_state'] = state;

    // Build authorization URL
    final authUrl = AuthConfig.buildWebAuthorizationUrl(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      state: state,
    );

    // Redirect to Cognito login
    html.window.location.href = authUrl;

    // This won't actually return since we're navigating away
    return AuthResult(success: true);
  } catch (e) {
    return AuthResult(success: false, error: 'Web authentication error: ${e.toString()}');
  }
}

/// Get stored tokens from localStorage
Future<Map<String, String?>> getStoredTokens() async {
  return {
    'access_token': html.window.localStorage['access_token'],
    'refresh_token': html.window.localStorage['refresh_token'],
    'id_token': html.window.localStorage['id_token'],
  };
}

/// Store tokens in localStorage
Future<void> storeTokens({
  String? accessToken,
  String? refreshToken,
  String? idToken,
}) async {
  if (accessToken != null) {
    html.window.localStorage['access_token'] = accessToken;
  }
  if (refreshToken != null) {
    html.window.localStorage['refresh_token'] = refreshToken;
  }
  if (idToken != null) {
    html.window.localStorage['id_token'] = idToken;
  }
}

/// Clear tokens from localStorage
Future<void> clearTokens() async {
  html.window.localStorage.remove('access_token');
  html.window.localStorage.remove('refresh_token');
  html.window.localStorage.remove('id_token');
}

/// Refresh access token via HTTP
Future<AuthResult> refreshToken(String refreshTokenValue) async {
  try {
    final tokenResponse = await http.post(
      Uri.parse(AuthConfig.tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': AuthConfig.clientId,
        'refresh_token': refreshTokenValue,
      },
    );

    if (tokenResponse.statusCode == 200) {
      final tokens = json.decode(tokenResponse.body);
      return AuthResult(
        success: true,
        accessToken: tokens['access_token'],
        refreshToken: tokens['refresh_token'],
        idToken: tokens['id_token'],
      );
    }
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }

  return AuthResult(success: false, error: 'Token refresh failed.');
}

/// Handle OAuth callback on web
Future<AuthResult?> handleWebCallback() async {
  final uri = Uri.parse(html.window.location.href);
  
  // Check if this is a callback with an auth code
  if (!uri.path.contains('/auth/callback')) return null;
  
  final code = uri.queryParameters['code'];
  final returnedState = uri.queryParameters['state'];
  final error = uri.queryParameters['error'];

  if (error != null) {
    return AuthResult(
      success: false,
      error: uri.queryParameters['error_description'] ?? error,
    );
  }

  if (code == null) return null;

  // Verify state
  final storedState = html.window.sessionStorage['oauth_state'];
  if (storedState != returnedState) {
    return AuthResult(
      success: false,
      error: 'Invalid OAuth state. Please try again.',
    );
  }

  // Get stored code verifier
  final codeVerifier = html.window.sessionStorage['code_verifier'];
  if (codeVerifier == null) {
    return AuthResult(
      success: false,
      error: 'Missing code verifier. Please try again.',
    );
  }

  try {
    // Exchange code for tokens
    final tokenResponse = await http.post(
      Uri.parse(AuthConfig.tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': AuthConfig.clientId,
        'code': code,
        'redirect_uri': AuthConfig.webRedirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (tokenResponse.statusCode == 200) {
      final tokens = json.decode(tokenResponse.body);
      
      // Store tokens in localStorage
      await storeTokens(
        accessToken: tokens['access_token'],
        refreshToken: tokens['refresh_token'],
        idToken: tokens['id_token'],
      );

      // Clear session storage
      html.window.sessionStorage.remove('code_verifier');
      html.window.sessionStorage.remove('oauth_state');

      // Clean URL
      html.window.history.replaceState(null, '', '/');

      return AuthResult(
        success: true,
        accessToken: tokens['access_token'],
        refreshToken: tokens['refresh_token'],
        idToken: tokens['id_token'],
      );
    } else {
      return AuthResult(
        success: false,
        error: 'Token exchange failed: ${tokenResponse.body}',
      );
    }
  } catch (e) {
    return AuthResult(
      success: false,
      error: 'Token exchange error: ${e.toString()}',
    );
  }
}
