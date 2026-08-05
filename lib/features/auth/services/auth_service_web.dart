import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../../../core/constants/auth_config.dart';
import 'auth_service.dart';

Map<String, dynamic> decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    final decoded = json.decode(utf8.decode(base64Url.decode(normalized)));
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  } catch (e) { return {}; }
}

void redirectToAdmin(String? token) {
  if (token == null) return;
  html.window.location.href = '/admin/?token=$token';
}

Future<AuthResult> signIn({
  String identityProvider = AuthConfig.googleIdentityProvider,
}) async {
  try {
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final state = generateRandomState();

    html.window.sessionStorage['code_verifier'] = codeVerifier;
    html.window.sessionStorage['oauth_state'] = state;

    final authUrl = AuthConfig.buildWebAuthorizationUrl(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      state: state,
      identityProvider: identityProvider,
    );

    html.window.location.href = authUrl;
    return AuthResult(success: true);
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }
}

Future<Map<String, String?>> getStoredTokens() async {
  return {
    'access_token': html.window.localStorage['access_token'],
    'refresh_token': html.window.localStorage['refresh_token'],
    'id_token': html.window.localStorage['id_token'],
  };
}

Future<void> storeTokens({String? accessToken, String? refreshToken, String? idToken}) async {
  if (accessToken != null) html.window.localStorage['access_token'] = accessToken;
  if (refreshToken != null) html.window.localStorage['refresh_token'] = refreshToken;
  if (idToken != null) html.window.localStorage['id_token'] = idToken;
}

Future<void> clearTokens() async {
  html.window.localStorage.clear();
}

Future<AuthResult> refreshToken(String refreshTokenValue) async {
  try {
    final response = await http.post(
      Uri.parse(AuthConfig.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'client_id': AuthConfig.clientId,
        'refresh_token': refreshTokenValue,
      },
    );
    if (response.statusCode == 200) {
      final tokens = json.decode(response.body);
      return AuthResult(success: true, accessToken: tokens['access_token'], idToken: tokens['id_token']);
    }
  } catch (e) { return AuthResult(success: false, error: e.toString()); }
  return AuthResult(success: false);
}

Future<AuthResult?> handleWebCallback() async {
  final uri = Uri.parse(html.window.location.href);
  if (!uri.path.contains('/auth/callback')) return null;
  
  final code = uri.queryParameters['code'];
  if (code == null) return null;

  final codeVerifier = html.window.sessionStorage['code_verifier'];
  try {
    final response = await http.post(
      Uri.parse(AuthConfig.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AuthConfig.clientId,
        'code': code,
        'redirect_uri': AuthConfig.webRedirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final tokens = json.decode(response.body);
      final String idToken = tokens['id_token'];
      final String accessToken = tokens['access_token'];

      final payload = decodeJwt(idToken);
      final List? groups = payload['cognito:groups'];
      if (groups != null && groups.contains('ADMIN')) {
        redirectToAdmin(accessToken);
        return null; 
      }

      await storeTokens(accessToken: accessToken, refreshToken: tokens['refresh_token'], idToken: idToken);
      html.window.history.replaceState(null, '', '/');
      return AuthResult(success: true, accessToken: accessToken, idToken: idToken);
    }
  } catch (e) { return AuthResult(success: false, error: e.toString()); }
  return null;
}