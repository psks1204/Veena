import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/auth_config.dart';
import 'auth_service.dart';

/// Desktop (Windows/Linux/macOS) Authentication Service
/// 
/// Uses url_launcher to open browser for OAuth and a local HTTP server
/// to receive the callback.

final _secureStorage = const FlutterSecureStorage();

// Local server port for OAuth callback
const int _callbackPort = 8765;

Map<String, dynamic> decodeJwt(String token) => {};
void redirectToAdmin(String? token) {}

String? _storedCodeVerifier;
HttpServer? _localServer;

Future<AuthResult> signIn() async {
  try {
    // Generate PKCE values
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final state = generateRandomState();
    
    _storedCodeVerifier = codeVerifier;

    // Build authorization URL for desktop
    final authUrl = AuthConfig.buildWebAuthorizationUrl(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      state: state,
      isDesktop: true,
    );

    // Start local server to receive callback
    final completer = Completer<AuthResult>();
    
    _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, _callbackPort);
    debugPrint('Local OAuth server listening on port $_callbackPort');

    // Handle incoming requests
    _localServer!.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/auth/callback') {
          final code = request.uri.queryParameters['code'];
          final returnedState = request.uri.queryParameters['state'];
          final error = request.uri.queryParameters['error'];

          if (error != null) {
            // Send error response
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(_buildHtmlResponse('Authentication Error', 'Error: $error. You can close this window.'))
              ..close();
            
            completer.complete(AuthResult(success: false, error: error));
            await _stopLocalServer();
            return;
          }

          if (code != null && returnedState == state) {
            // Exchange code for tokens
            final tokenResult = await _exchangeCodeForTokens(code, codeVerifier);
            
            // Send success response
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(_buildHtmlResponse('Authentication Successful', 'You can close this window and return to the app.'))
              ..close();
            
            completer.complete(tokenResult);
            await _stopLocalServer();
          } else {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..headers.contentType = ContentType.html
              ..write(_buildHtmlResponse('Invalid Request', 'State mismatch or missing code.'))
              ..close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      } catch (e) {
        debugPrint('Error handling callback: $e');
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Error')
          ..close();
      }
    });

    // Launch browser
    final uri = Uri.parse(authUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _stopLocalServer();
      return AuthResult(success: false, error: 'Could not launch browser');
    }

    // Wait for callback with timeout
    return await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () async {
        await _stopLocalServer();
        return AuthResult(success: false, error: 'Authentication timeout');
      },
    );
  } catch (e) {
    await _stopLocalServer();
    return AuthResult(success: false, error: e.toString());
  }
}

Future<AuthResult> _exchangeCodeForTokens(String code, String codeVerifier) async {
  try {
    final response = await http.post(
      Uri.parse(AuthConfig.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AuthConfig.clientId,
        'code': code,
        'redirect_uri': 'http://localhost:$_callbackPort/auth/callback',
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AuthResult(
        success: true,
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        idToken: data['id_token'],
      );
    } else {
      debugPrint('Token exchange failed: ${response.body}');
      return AuthResult(success: false, error: 'Token exchange failed: ${response.statusCode}');
    }
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }
}

Future<void> _stopLocalServer() async {
  await _localServer?.close(force: true);
  _localServer = null;
}

String _buildHtmlResponse(String title, String message) {
  return '''
<!DOCTYPE html>
<html>
<head>
  <title>$title</title>
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex; 
      justify-content: center; 
      align-items: center; 
      height: 100vh; 
      margin: 0;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: white;
    }
    .container { 
      text-align: center; 
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 16px;
      backdrop-filter: blur(10px);
    }
    h1 { color: #E91E63; margin-bottom: 16px; }
    p { color: #ccc; }
  </style>
</head>
<body>
  <div class="container">
    <h1>$title</h1>
    <p>$message</p>
  </div>
</body>
</html>
''';
}

Future<Map<String, String?>> getStoredTokens() async {
  return {
    'access_token': await _secureStorage.read(key: 'access_token'),
    'refresh_token': await _secureStorage.read(key: 'refresh_token'),
    'id_token': await _secureStorage.read(key: 'id_token'),
  };
}

Future<void> storeTokens({String? accessToken, String? refreshToken, String? idToken}) async {
  if (accessToken != null) await _secureStorage.write(key: 'access_token', value: accessToken);
  if (refreshToken != null) await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  if (idToken != null) await _secureStorage.write(key: 'id_token', value: idToken);
}

Future<void> clearTokens() async {
  await _secureStorage.deleteAll();
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
      final data = jsonDecode(response.body);
      return AuthResult(
        success: true,
        accessToken: data['access_token'],
        idToken: data['id_token'],
      );
    }
  } catch (e) {
    return AuthResult(success: false, error: e.toString());
  }
  return AuthResult(success: false);
}

Future<AuthResult?> handleWebCallback() async => null;
