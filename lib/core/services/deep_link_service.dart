import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Deep Link Service
///
/// Listens for incoming https://veenamusiconline.com/song/{songId} links
/// on Android (App Links) and iOS (Universal Links).
///
/// Usage:
///   1. Call [initialize] once during app startup.
///   2. After a successful login, read [pendingSongId].
///   3. If non-null, fetch + play the media, then call [consume].
class DeepLinkService extends ChangeNotifier {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// The songId extracted from the last unhandled deep link.
  /// Null when there is no pending link.
  String? pendingSongId;

  /// Whether we have already consumed the initial (cold-start) link.
  bool _initialLinkHandled = false;

  /// Initialize: capture cold-start link and subscribe to foreground links.
  Future<void> initialize() async {
    // ── Cold start (app was not running) ──────────────────────────────────
    if (!_initialLinkHandled) {
      _initialLinkHandled = true;
      try {
        final initialUri = await _appLinks.getInitialLink();
        if (initialUri != null) {
          debugPrint('🔗 DeepLinkService: cold-start link → $initialUri');
          _handleUri(initialUri);
        }
      } catch (e) {
        debugPrint('⚠️ DeepLinkService: error reading initial link: $e');
      }
    }

    // ── Foreground / background resume ────────────────────────────────────
    _linkSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 DeepLinkService: incoming link → $uri');
        _handleUri(uri);
      },
      onError: (e) {
        debugPrint('⚠️ DeepLinkService: stream error: $e');
      },
    );
  }

  /// Parse a URI and extract the songId if it matches /song/{id} or veena://song/{id}.
  void _handleUri(Uri uri) {
    debugPrint('🔗 DeepLinkService: parsing uri → scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}');
    String? songId;

    final segments = uri.pathSegments;
    // Standard web URL: https://veenamusiconline.com/song/{songId}
    if (segments.length >= 2 && segments[0] == 'song') {
      songId = segments[1];
    } 
    // Custom scheme format 1: veena://song/{songId} (host = 'song', path = '/{songId}')
    else if (uri.scheme == 'veena' && uri.host == 'song' && segments.isNotEmpty) {
      songId = segments[0];
    }
    // Custom scheme format 2: veena://open?songId={songId} or ?id={songId}
    else if (uri.queryParameters.containsKey('songId')) {
      songId = uri.queryParameters['songId'];
    } else if (uri.queryParameters.containsKey('id')) {
      songId = uri.queryParameters['id'];
    }

    if (songId != null && songId.isNotEmpty) {
      debugPrint('✅ DeepLinkService: extracted songId = $songId');
      pendingSongId = songId;
      notifyListeners();
    }
  }

  /// Mark the pending link as consumed after navigating to the song.
  void consume() {
    if (pendingSongId != null) {
      pendingSongId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
