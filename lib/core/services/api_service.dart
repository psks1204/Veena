import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://d17362b1w27h09.cloudfront.net/api'; // Update for production

  Future<Map<String, String>> getHeaders([String? token]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(token),
    );
    
    return _handleResponse(response);
  }

  /// Get raw string content from a URL (used for lyrics, etc.)
  Future<String?> getRaw(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    return null;
  }

  Future<dynamic> post(String endpoint, {dynamic body, String? token}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    );
    
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(token),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
