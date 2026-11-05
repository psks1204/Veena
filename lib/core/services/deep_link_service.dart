import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Deep Link Service
///
/// Listens for incoming links on Android (App Links) and iOS (Universal Links):
/// - https://veenamusiconline.com/song/{songId}
/// - https://veenamusiconline.com/reel/{reelId}
/// - veena://song/{songId}
/// - veena://reel/{reelId}
class DeepLinkService extends ChangeNotifier {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// The songId extracted from the last unhandled deep link.
  /// Null when there is no pending link.
  String? pendingSongId;

  /// The reelId extracted from the last unhandled deep link.
  /// Null when there is no pending link.
  String? pendingReelId;

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

  /// Parse a URI and extract songId or reelId.
  void _handleUri(Uri uri) {
    debugPrint(
      '🔗 DeepLinkService: parsing uri → scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}',
    );

    final segments = uri.pathSegments;

    // 1. Reel links
    String? reelId;
    if (segments.length >= 2 && segments[0] == 'reel') {
      reelId = segments[1];
    } else if (uri.scheme == 'veena' && uri.host == 'reel' && segments.isNotEmpty) {
      reelId = segments[0];
    } else if (uri.queryParameters.containsKey('reelId')) {
      reelId = uri.queryParameters['reelId'];
    }

    if (reelId != null && reelId.isNotEmpty) {
      debugPrint('✅ DeepLinkService: extracted reelId = $reelId');
      pendingReelId = reelId;
      notifyListeners();
      return;
    }

    // 2. Song links
    String? songId;
    if (segments.length >= 2 && segments[0] == 'song') {
      songId = segments[1];
    } else if (uri.scheme == 'veena' && uri.host == 'song' && segments.isNotEmpty) {
      songId = segments[0];
    } else if (uri.queryParameters.containsKey('songId')) {
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

  /// Mark the pending song link as consumed after navigating to the song.
  void consume() {
    consumeSong();
  }

  /// Mark the pending song link as consumed.
  void consumeSong() {
    if (pendingSongId != null) {
      pendingSongId = null;
      notifyListeners();
    }
  }

  /// Mark the pending reel link as consumed after navigating to the reel.
  void consumeReel() {
    if (pendingReelId != null) {
      pendingReelId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
