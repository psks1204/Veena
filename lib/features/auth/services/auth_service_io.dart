import 'dart:io' show Platform;
import 'auth_service.dart';

// Import both implementations
import 'auth_service_mobile.dart' as mobile;
import 'auth_service_desktop.dart' as desktop;

// Check if running on desktop
bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

Map<String, dynamic> decodeJwt(String token) => 
    _isDesktop ? desktop.decodeJwt(token) : mobile.decodeJwt(token);

void redirectToAdmin(String? token) => 
    _isDesktop ? desktop.redirectToAdmin(token) : mobile.redirectToAdmin(token);

Future<AuthResult> signIn() => 
    _isDesktop ? desktop.signIn() : mobile.signIn();

Future<Map<String, String?>> getStoredTokens() => 
    _isDesktop ? desktop.getStoredTokens() : mobile.getStoredTokens();

Future<void> storeTokens({String? accessToken, String? refreshToken, String? idToken}) => 
    _isDesktop 
        ? desktop.storeTokens(accessToken: accessToken, refreshToken: refreshToken, idToken: idToken)
        : mobile.storeTokens(accessToken: accessToken, refreshToken: refreshToken, idToken: idToken);

Future<void> clearTokens() => 
    _isDesktop ? desktop.clearTokens() : mobile.clearTokens();

Future<AuthResult> refreshToken(String refreshTokenValue) => 
    _isDesktop ? desktop.refreshToken(refreshTokenValue) : mobile.refreshToken(refreshTokenValue);

Future<AuthResult?> handleWebCallback() async => null;
