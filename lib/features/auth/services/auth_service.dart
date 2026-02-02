import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/auth_config.dart';
import '../../../core/services/push_notification_service.dart';
// Conditional import based on platform
import 'auth_service_mobile.dart' if (dart.library.html) 'auth_service_web.dart' as platform;

class AuthResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? error;
  AuthResult({required this.success, this.accessToken, this.refreshToken, this.idToken, this.error});
}

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  String? _errorMessage;
  bool _isAuthInProgress = false; // Flag to prevent re-initialization during OAuth
  bool _isSigningOut = false; // Flag to prevent re-entrant signOut calls

  AuthState get state => _state;
  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _accessToken != null;
  bool get isSigningOut => _isSigningOut; // Expose for ApiService to check

  // User profile data (fetched from userinfo endpoint)
  String? _userName;
  String? _userEmail;
  String? _userPicture;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPicture => _userPicture;
  String get userInitials {
    final name = _userName ?? _userEmail ?? 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Fetch user profile from Cognito userinfo endpoint
  Future<void> _fetchUserProfile() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://${AuthConfig.cognitoDomain}/oauth2/userInfo'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Try multiple possible claim names (Cognito returns given_name from Google)
        _userName = data['name'] ?? 
                    data['given_name'] ?? 
                    data['preferred_username'];
        _userEmail = data['email'];
        _userPicture = data['picture'];
        
        // Fallback: use email username if no proper name
        if (_userName == null || _userName!.startsWith('Google_')) {
          if (_userEmail != null && _userEmail!.contains('@')) {
            final emailName = _userEmail!.split('@')[0];
            _userName = emailName.split('.').map((s) => 
              s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s
            ).join(' ');
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> initialize() async {
    // Don't reset state if OAuth is in progress (app may restart during Chrome Custom Tab)
    if (_isAuthInProgress) {
      debugPrint('[AuthService] Auth in progress, skipping re-initialization');
      return;
    }
    
    _state = AuthState.loading;
    notifyListeners();

    try {
      if (kIsWeb) {
        final result = await platform.handleWebCallback();
        if (result != null && result.success) {
          _accessToken = result.accessToken;
          _idToken = result.idToken;
          _state = AuthState.authenticated;
          notifyListeners();
          return;
        }
      }

      final tokens = await platform.getStoredTokens();
      _accessToken = tokens['access_token'];
      _refreshToken = tokens['refresh_token'];
      _idToken = tokens['id_token'];

      if (_accessToken != null) {
        if (kIsWeb && _idToken != null) {
          final payload = platform.decodeJwt(_idToken!);
          final List? groups = payload['cognito:groups'];
          if (groups != null && groups.contains('ADMIN')) {
            platform.redirectToAdmin(_accessToken);
            return;
          }
        }
        _state = AuthState.authenticated;
        await _fetchUserProfile(); // Fetch real Google profile data
        
        // Register FCM token after successful auth restore
        if (!kIsWeb) {
          PushNotificationService().registerFcmToken();
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    _isAuthInProgress = true; // Mark auth as in progress
    notifyListeners();

    try {
      final result = await platform.signIn();
      _isAuthInProgress = false; // Auth completed
      if (kIsWeb) return result.success; 

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
        await _fetchUserProfile(); // Fetch real Google profile data
        
        notifyListeners();
        
        // Register FCM token AFTER state change (ensures ApiService has token set)
        if (!kIsWeb) {
          // Use post-frame callback to ensure UI has rebuilt and ApiService has token
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PushNotificationService().registerFcmToken();
          });
        }
        
        return true;
      } else {
        _isAuthInProgress = false;
        _state = AuthState.error;
        _errorMessage = result.error ?? 'Authentication failed.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthInProgress = false;
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    // Prevent re-entrant signOut calls (breaks infinite 401 loop)
    if (_isSigningOut) {
      debugPrint('[AuthService] SignOut already in progress, skipping');
      return;
    }
    _isSigningOut = true;
    
    _state = AuthState.loading;
    notifyListeners();
    try {
      // Clear tokens FIRST before any API calls
      await platform.clearTokens();
      _accessToken = null;
      _refreshToken = null;
      _idToken = null;
      _userName = null;
      _userEmail = null;
      _userPicture = null;
      _state = AuthState.unauthenticated;
      
      // Try to unregister FCM token (fire and forget - ignore errors)
      if (!kIsWeb) {
        PushNotificationService().unregisterFcmToken().catchError((e) {
          debugPrint('[AuthService] FCM unregister failed (expected): $e');
        });
      }
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
      _state = AuthState.unauthenticated;
    }
    _isSigningOut = false;
    notifyListeners();
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final result = await platform.refreshToken(_refreshToken!);
      if (result.success) {
        _accessToken = result.accessToken;
        _idToken = result.idToken;
        await platform.storeTokens(accessToken: _accessToken, idToken: _idToken);
        return true;
      }
    } catch (e) { debugPrint(e.toString()); }
    return false;
  }
}

// PKCE Helpers
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
