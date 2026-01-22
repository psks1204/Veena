import 'package:flutter/foundation.dart';

/// AWS Cognito Authentication Configuration
/// 
/// Production configuration for OAuth PKCE flow with Google.
class AuthConfig {
  AuthConfig._();

  /// Cognito Domain
  static const String issuer = 'cognito-idp.ap-south-1.amazonaws.com/ap-south-1_cuVCqjF2k';
  static const String cognitoDomain = 'veena-auth.auth.ap-south-1.amazoncognito.com';
  
  /// Full authorization endpoint (uses Hosted UI domain)
  static const String authorizationEndpoint = 
      'https://$cognitoDomain/oauth2/authorize';
  
  /// Token endpoint
  static const String tokenEndpoint = 
      'https://$cognitoDomain/oauth2/token';
  
  /// Logout endpoint
  static const String logoutEndpoint = 'https://$cognitoDomain/logout';
  
  /// Client ID (public - no secret needed for PKCE)
  static const String clientId = '8snvvu2cchipad20n6umug5l0';

  /// OAuth scopes
  static const List<String> scopes = ['openid', 'email', 'profile'];
  
  /// Redirect URI for mobile (deep link)
  static const String redirectUri = 'veena://auth/callback';


  /// Redirect URI for web
  /// Development: uses fixed localhost:3000
  /// Production: uses current origin (e.g., CloudFront URL)
  static String get webRedirectUri {
    if (kIsWeb && kReleaseMode) {
      return '${Uri.base.origin}/auth/callback';
    }
    return 'http://localhost:3000/auth/callback';
  }
  
  /// Alternative common ports - add all these to Cognito if testing on different ports
  /// http://localhost:3000/auth/callback
  /// http://localhost:5000/auth/callback
  /// http://localhost:52024/auth/callback
  
  /// Post-logout redirect URI
  static const String postLogoutRedirectUri = 'veena://auth/logout';
  
  /// Build the full authorization URL for web OAuth
  static String buildWebAuthorizationUrl({
    required String codeVerifier,
    required String codeChallenge,
    required String state,
  }) {
    final params = {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': webRedirectUri,
      'scope': scopes.join(' '),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'identity_provider': 'Google',
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$authorizationEndpoint?$queryString';
  }
}

