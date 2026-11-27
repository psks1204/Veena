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

  // Read-only token access for specialized requests (e.g., binary downloads).
  String? get accessToken => _accessToken;

  /// Called when the session is over — a request was rejected and the token
  /// could not be refreshed. Should sign the user out.
  OnUnauthorizedCallback? onUnauthorized;

  /// Callback to be invoked when a 401 is received, to attempt a token refresh
  RefreshTokenCallback? onRefreshToken;

  /// Set the access token for authenticated requests
  void setAccessToken(String? token) {
    if (_accessToken == token) return;
    _accessToken = token;
    if (token != null) debugPrint('[ApiService] Access token updated');
  }

  /// Clear the access token (used during logout)
  void clearAccessToken() {
    _accessToken = null;
  }

  /// Get headers with authentication
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Send a request, recovering from a 401 where possible.
  ///
  /// On a 401:
  ///  1. If the token was replaced while the request was in flight (another
  ///     request refreshed it, or the user signed in again), resend once with
  ///     the current token.
  ///  2. Otherwise try to refresh the token and resend.
  ///  3. If the refresh fails, the session is over: [onUnauthorized] signs the
  ///     user out. This must happen however soon after launch or sign-in the
  ///     401 arrives — an expired token restored at startup fails on its very
  ///     first requests, and ignoring those left users stuck on the
  ///     date-of-birth gate with a dead session.
  ///
  /// A 401 that comes back for a freshly refreshed token is not an expired
  /// session: the backend also answers 401 for actions the user may not take
  /// (e.g. editing a playlist they don't own), so that is surfaced as an
  /// error without signing out.
  ///
  /// [requestFn] must read the current token each time it is called.
  Future<dynamic> _retryRequest(
    Future<http.Response> Function() requestFn, {
    bool skipUnauthorizedCallback = false,
  }) async {
    var sentWith = _accessToken;
    var response = await requestFn();
    if (response.statusCode != 401 || skipUnauthorizedCallback) {
      return _handleResponse(response);
    }

    // 1. Sent with a token that has since been replaced: resend once.
    if (_accessToken != null && _accessToken != sentWith) {
      sentWith = _accessToken;
      response = await requestFn();
      if (response.statusCode != 401) return _handleResponse(response);
    }

    // Signed out (or never signed in): there is no session to recover or end.
    if (_accessToken == null) return _handleResponse(response);

    // 2. Refresh and resend.
    debugPrint('🔄 401 received, attempting token refresh...');
    var refreshed = false;
    try {
      refreshed = await onRefreshToken?.call() ?? false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
    }
    if (refreshed) {
      debugPrint('✅ Token refresh successful, retrying request...');
      return _handleResponse(await requestFn());
    }

    // 3. The session can't be renewed. Only end it if it is still the
    // session this request was made with (not one started since).
    debugPrint('❌ Token refresh failed');
    if (_accessToken != null && _accessToken == sentWith) {
      debugPrint('🔒 Session expired — signing out');
      onUnauthorized?.call();
    }
    return _handleResponse(response);
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

  /// Turn a response into decoded JSON, or throw [ApiException].
  /// Signing out on 401 is decided by [_retryRequest], not here.
  dynamic _handleResponse(http.Response response) {
    debugPrint('📥 Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      debugPrint('🔒 401 Unauthorized received');
      throw ApiException(
        _extractErrorMessage(
          response,
          fallback: 'Unauthorized - Session expired',
        ),
        response.statusCode,
      );
    } else if (response.statusCode == 404) {
      throw ApiException(
        _extractErrorMessage(response, fallback: 'Resource not found'),
        response.statusCode,
      );
    } else {
      throw ApiException(
        _extractErrorMessage(
          response,
          fallback:
              'Request failed: ${response.reasonPhrase ?? 'Unknown error'}',
        ),
        response.statusCode,
      );
    }
  }

  String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    final body = response.body.trim();
    if (body.isEmpty) return fallback;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const [
          'message',
          'error',
          'details',
          'description',
        ]) {
          final value = decoded[key];
          if (value == null) continue;
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back below.
    }

    return body;
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
