/// AWS Cognito Authentication Configuration
/// 
/// Production configuration for OAuth PKCE flow with Google.
class AuthConfig {
  AuthConfig._();

  /// Cognito Domain
  static const String cognitoDomain = 'veena-auth.auth.ap-south-1.amazoncognito.com';
  
  /// Full authorization endpoint
  static const String authorizationEndpoint = 
      'https://$cognitoDomain/oauth2/authorize';
  
  /// Token endpoint
  static const String tokenEndpoint = 
      'https://$cognitoDomain/oauth2/token';
  
  /// Logout endpoint
  static const String logoutEndpoint = 
      'https://$cognitoDomain/logout';
  
  /// Client ID (public - no secret needed for PKCE)
  static const String clientId = 'd8jr78io0e1l7b7bu8eva7vqr';
  
  /// OAuth scopes
  static const List<String> scopes = ['openid', 'email', 'profile'];
  
  /// Redirect URI for mobile (deep link)
  static const String redirectUri = 'veena://auth/callback';
  
  /// Post-logout redirect URI
  static const String postLogoutRedirectUri = 'veena://auth/logout';
}
