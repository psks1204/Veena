import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Callback type for handling 401 Unauthorized responses
typedef OnUnauthorizedCallback = void Function();

/// API Service
/// 
/// Central HTTP client for all Veena API calls.
/// Handles authentication, base URL, and error handling.
class ApiService {
  static const String baseUrl = 'https://veena.dgfly.in/api';

  String? _accessToken;
  DateTime? _tokenSetTime; // Track when token was set for grace period
  
  /// Callback to be invoked when a 401 Unauthorized response is received
  /// This should trigger logout and redirect to login
  OnUnauthorizedCallback? onUnauthorized;
  
  /// Set the access token for authenticated requests
  void setAccessToken(String? token) {
    // Only update if token actually changed
    if (_accessToken == token) return;
    
    _accessToken = token;
    if (token != null) {
      _tokenSetTime = DateTime.now();
      debugPrint('[ApiService] Token set at $_tokenSetTime');
    }
  }
  
  /// Clear the access token (used during logout)
  void clearAccessToken() {
    _accessToken = null;
    _tokenSetTime = null;
  }
  
  /// Get headers with authentication
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
  
  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      debugPrint('🌐 GET: $uri');
      
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }
  
  /// POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      debugPrint('🌐 POST: $uri');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      rethrow;
    }
  }
  
  /// PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      debugPrint('🌐 PUT: $uri');
      
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
      rethrow;
    }
  }
  
  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      debugPrint('🌐 DELETE: $uri');
      
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
      rethrow;
    }
  }
  
  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      debugPrint('🔒 401 Unauthorized received');
      // Only trigger logout if:
      // 1. We have a token set
      // 2. Token was set more than 3 seconds ago (grace period for stale requests)
      final shouldLogout = _accessToken != null && 
          (_tokenSetTime == null || 
           DateTime.now().difference(_tokenSetTime!).inSeconds > 3);
      
      if (shouldLogout) {
        debugPrint('🔒 Triggering logout (token expired)');
        onUnauthorized?.call();
      } else {
        debugPrint('🔒 Ignoring 401 - within grace period after login');
      }
      throw ApiException('Unauthorized - Session expired', response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found', response.statusCode);
    } else {
      throw ApiException(
        'Request failed: ${response.reasonPhrase}',
        response.statusCode,
      );
    }
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
  
  /// Check if this is an unauthorized error
  bool get isUnauthorized => statusCode == 401;
}
