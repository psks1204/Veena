import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Callback type for handling 401 Unauthorized responses
typedef OnUnauthorizedCallback = void Function();

/// Callback type for refreshing access token
/// Returns true if refresh was successful
typedef RefreshTokenCallback = Future<bool> Function();

/// API Service
///
/// Central HTTP client for all Veena API calls.
/// Handles authentication, base URL, and error handling.
class ApiService {
  static const String baseUrl = 'https://veena.dgfly.in/api';

  String? _accessToken;
  DateTime? _tokenSetTime; // Track when token was set for grace period

  // Read-only token access for specialized requests (e.g., binary downloads).
  String? get accessToken => _accessToken;

  /// Callback to be invoked when a 401 Unauthorized response is received
  /// This should trigger logout and redirect to login
  OnUnauthorizedCallback? onUnauthorized;

  /// Callback to be invoked when a 401 is received, to attempt a token refresh
  RefreshTokenCallback? onRefreshToken;

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

  /// Helper: Execute request with retry logic for 401
  Future<dynamic> _retryRequest(
    Future<http.Response> Function() requestFn, {
    bool skipUnauthorizedCallback = false,
  }) async {
    try {
      final response = await requestFn();

      // Check for 401
      if (response.statusCode == 401 && !skipUnauthorizedCallback) {
        // Try refresh if callback is available
        if (onRefreshToken != null) {
          debugPrint('🔄 401 received, attempting token refresh...');
          try {
            final success = await onRefreshToken!();
            if (success) {
              debugPrint('✅ Token refresh successful, retrying request...');
              // Retry request (ApiService token should have been updated by callback)
              final retryResponse = await requestFn();
              return _handleResponse(
                retryResponse,
                skipUnauthorizedCallback: skipUnauthorizedCallback,
              );
            } else {
              debugPrint('❌ Token refresh failed');
            }
          } catch (e) {
            debugPrint('❌ Token refresh error: $e');
          }
        }
      }

      return _handleResponse(
        response,
        skipUnauthorizedCallback: skipUnauthorizedCallback,
      );
    } catch (e) {
      // If we rethrew from inside, it bubbles up
      rethrow;
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      debugPrint('🌐 GET: $uri');

      return _retryRequest(() => http.get(uri, headers: _headers));
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }

  /// POST request
  /// [skipUnauthorizedCallback] - If true, a 401 response won't trigger the onUnauthorized callback
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    bool skipUnauthorizedCallback = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      debugPrint('🌐 POST: $uri');

      return _retryRequest(
        () => http.post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        skipUnauthorizedCallback: skipUnauthorizedCallback,
      );
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

      return _retryRequest(
        () => http.put(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
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

      return _retryRequest(() => http.delete(uri, headers: _headers));
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
      rethrow;
    }
  }

  /// Multipart POST request (for file uploads)
  Future<dynamic> multipartPost(
    String endpoint, {
    required String filePath,
    required String fieldName,
    String? contentType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 MULTIPART POST: $uri');

      return _retryRequest(() async {
        final request = http.MultipartRequest('POST', uri);

        // Add auth header
        if (_accessToken != null) {
          request.headers['Authorization'] = 'Bearer $_accessToken';
        }

        // Add file with explicit content type if provided
        MediaType? mediaType;
        if (contentType != null) {
          try {
            mediaType = MediaType.parse(contentType);
          } catch (_) {}
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            filePath,
            contentType: mediaType,
          ),
        );

        final streamResponse = await request.send();
        return await http.Response.fromStream(streamResponse);
      });
    } catch (e) {
      debugPrint('❌ MULTIPART POST Error: $e');
      rethrow;
    }
  }

  /// Multipart POST from bytes (for web where file path isn't available)
  Future<dynamic> multipartPostBytes(
    String endpoint, {
    required List<int> bytes,
    required String fieldName,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 MULTIPART POST (bytes): $uri');

      return _retryRequest(() async {
        final request = http.MultipartRequest('POST', uri);

        if (_accessToken != null) {
          request.headers['Authorization'] = 'Bearer $_accessToken';
        }

        MediaType? mediaType;
        if (contentType != null) {
          try {
            mediaType = MediaType.parse(contentType);
          } catch (_) {}
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: fileName,
            contentType: mediaType,
          ),
        );

        final streamResponse = await request.send();
        return await http.Response.fromStream(streamResponse);
      });
    } catch (e) {
      debugPrint('❌ MULTIPART POST (bytes) Error: $e');
      rethrow;
    }
  }

  /// Multipart POST with arbitrary string fields + multiple files + upload progress
  ///
  /// Progress is reported as 0.0–1.0.  Uses a properly ordered stream pipeline:
  /// client.send() is initiated FIRST, then the body is piped into the sink.
  /// Total progress is estimated from the sum of raw file byte sizes.
  Future<dynamic> multipartPostWithFieldsAndProgress(
    String endpoint, {
    required Map<String, String> fields,
    required List<dynamic>
    files, // List<MultipartFileData> from channel_service
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 MULTIPART POST (fields+progress): $uri');

      return _retryRequest(() async {
        final request = http.MultipartRequest('POST', uri);

        if (_accessToken != null) {
          request.headers['Authorization'] = 'Bearer $_accessToken';
        }

        // Add string fields
        for (final entry in fields.entries) {
          request.fields[entry.key] = entry.value;
        }

        // Compute approximate total bytes for progress (sum of raw file bytes)
        int approximateTotal = 0;
        for (final entry in fields.entries) {
          approximateTotal += entry.key.length + entry.value.length + 80;
        }

        // Add file parts (files is List<MultipartFileData> — accessed via duck-typing)
        for (final f in files) {
          final fieldName = f.fieldName as String;
          final bytes = f.bytes as List<int>;
          final fileName = f.fileName as String;
          final contentType = f.contentType as String?;

          MediaType? mediaType;
          if (contentType != null) {
            try {
              mediaType = MediaType.parse(contentType);
            } catch (_) {}
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: fileName,
              contentType: mediaType,
            ),
          );
          approximateTotal += bytes.length;
        }

        // BrowserClient does not reliably support the custom streamed multipart
        // path below and can fail with ERR_HTTP2_PROTOCOL_ERROR / Failed to fetch.
        // Use the standard MultipartRequest send path on web.
        if (kIsWeb) {
          onProgress?.call(0.1);
          final streamResponse = await request.send();
          onProgress?.call(0.95);
          onProgress?.call(1.0);
          return await http.Response.fromStream(streamResponse);
        }

        if (onProgress == null) {
          final streamResponse = await request.send();
          return await http.Response.fromStream(streamResponse);
        }

        // ── Streaming with progress tracking ─────────────────────────
        // Key ordering: create StreamedRequest → start send() → pipe body → await response
        final client = http.Client();
        try {
          final streamedRequest = http.StreamedRequest(
            request.method,
            request.url,
          );
          // Copy headers AFTER adding all parts so content-type boundary is stable
          streamedRequest.headers.addAll(request.headers);

          // Start the send FIRST so the HTTP client is ready to receive chunks
          final responseFuture = client.send(streamedRequest);

          // Finalize the multipart request to get its byte stream, then pipe it
          int bytesSent = 0;
          final bodyStream = request.finalize();
          await for (final chunk in bodyStream) {
            streamedRequest.sink.add(chunk);
            bytesSent += chunk.length;
            if (approximateTotal > 0) {
              // Clamp to 0.95 — the final 5% represents server processing time
              final progress = (bytesSent / approximateTotal).clamp(0.0, 0.95);
              onProgress(progress);
            }
          }
          await streamedRequest.sink.close();

          // Await server response (server processes the upload)
          final streamedResponse = await responseFuture;
          onProgress(1.0);
          return await http.Response.fromStream(streamedResponse);
        } finally {
          client.close();
        }
      });
    } catch (e) {
      debugPrint('❌ MULTIPART POST (fields+progress) Error: $e');
      rethrow;
    }
  }

  /// Handle HTTP response
  /// [skipUnauthorizedCallback] - If true, a 401 won't trigger logout callback
  dynamic _handleResponse(
    http.Response response, {
    bool skipUnauthorizedCallback = false,
  }) {
    debugPrint('📥 Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      debugPrint('🔒 401 Unauthorized received');

      // Skip logout callback if requested (used during logout to prevent loops)
      if (skipUnauthorizedCallback) {
        debugPrint(
          '🔒 Skipping logout callback (skipUnauthorizedCallback=true)',
        );
        throw ApiException(
          'Unauthorized - Session expired',
          response.statusCode,
        );
      }

      // Only trigger logout if:
      // 1. We have a token set
      // 2. Token was set more than 3 seconds ago (grace period for stale requests)
      final shouldLogout =
          _accessToken != null &&
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
