import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API Service
/// 
/// Central HTTP client for all Veena API calls.
/// Handles authentication, base URL, and error handling.
class ApiService {
  static const String baseUrl = 'https://d17362b1w27h09.cloudfront.net/api';
  
  String? _accessToken;
  
  /// Set the access token for authenticated requests
  void setAccessToken(String? token) {
    _accessToken = token;
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
      throw ApiException('Unauthorized - Please login again', response.statusCode);
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
}
