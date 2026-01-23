// Stub file for unsupported platforms
// This should never be reached in practice
import 'auth_service.dart';

Map<String, dynamic> decodeJwt(String token) => {};
void redirectToAdmin(String? token) {}

Future<AuthResult> signIn() async => 
    AuthResult(success: false, error: 'Unsupported platform');

Future<Map<String, String?>> getStoredTokens() async => {};

Future<void> storeTokens({String? accessToken, String? refreshToken, String? idToken}) async {}

Future<void> clearTokens() async {}

Future<AuthResult> refreshToken(String refreshTokenValue) async => 
    AuthResult(success: false);

Future<AuthResult?> handleWebCallback() async => null;
