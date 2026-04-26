import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/channel_service.dart';

const _kChannelNameConfirmedKey = 'channel_name_confirmed';

/// Channel Provider
///
/// Manages the current user's channel state.
/// - Initializes by fetching (or auto-creating) the channel via GET /user/channel
/// - Tracks whether the user needs to complete the channel name setup step
///   (first-login only, via a SharedPreferences flag)
/// - Holds the media list for My Channel screen
/// - Exposes upload progress for the upload screen
class ChannelProvider extends ChangeNotifier {
  final ChannelService _service;
  final SharedPreferences _prefs;

  ChannelProvider(this._service, this._prefs);

  // ── State ────────────────────────────────────────────────────────

  ChannelResponse? _channel;
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;
  bool _needsChannelSetup = false;

  // Media list state
  List<UserMediaResponse> _media = [];
  bool _mediaLoading = false;
  bool _mediaHasMore = true;
  int _mediaPage = 0;
  String? _mediaApprovalFilter;

  // Upload progress state
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _uploadError;

  // ── Getters ──────────────────────────────────────────────────────

  ChannelResponse? get channel => _channel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;

  /// True only on first login until the user confirms/skips channel setup
  bool get needsChannelSetup => _needsChannelSetup;

  List<UserMediaResponse> get media => _media;
  bool get mediaLoading => _mediaLoading;
  bool get mediaHasMore => _mediaHasMore;

  double get uploadProgress => _uploadProgress;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  // ── Initialization ───────────────────────────────────────────────

  /// Called once from _AppRouterState after the profile setup gate passes.
  Future<void> initializeOnLogin() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _channel = await _service.getOrCreateChannel();

      // Determine if the user needs to set up their channel name.
      // Rule: only prompt when the channel has NO name at all.
      // If the channel already has any name (user-set or auto), skip the prompt
      // and mark the flag so we never check again.
      final confirmed = _prefs.getBool(_kChannelNameConfirmedKey) ?? false;
      if (!confirmed) {
        final name = (_channel?.channelName ?? '').trim();
        if (name.isEmpty) {
          // No name at all — ask the user to set one
          _needsChannelSetup = true;
        } else {
          // Channel already has a name — silently mark as done
          await _prefs.setBool(_kChannelNameConfirmedKey, true);
        }
      }
    } catch (e) {
      debugPrint('❌ ChannelProvider.initializeOnLogin: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark channel setup as confirmed (user saved or skipped)
  Future<void> markChannelSetupDone() async {
    _needsChannelSetup = false;
    await _prefs.setBool(_kChannelNameConfirmedKey, true);
    notifyListeners();
  }

  // ── Channel CRUD ─────────────────────────────────────────────────

  Future<bool> createChannel({
    required String channelName,
    String? channelHandle,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _channel = await _service.createChannel(
        channelName: channelName,
        channelHandle: channelHandle,
        description: description,
      );
      return true;
    } catch (e) {
      debugPrint('❌ ChannelProvider.createChannel: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChannel({
    String? channelName,
    String? channelHandle,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _channel = await _service.updateChannel(
        channelName: channelName,
        channelHandle: channelHandle,
        description: description,
      );
      return true;
    } catch (e) {
      debugPrint('❌ ChannelProvider.updateChannel: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadChannelImage({
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _channel = await _service.uploadChannelImage(
        filePath: filePath,
        bytes: bytes,
        fileName: fileName,
      );
      return true;
    } catch (e) {
      debugPrint('❌ ChannelProvider.uploadChannelImage: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Media list ───────────────────────────────────────────────────

  Future<void> loadMedia({String? approvalFilter, bool refresh = false}) async {
    if (refresh) {
      _media = [];
      _mediaPage = 0;
      _mediaHasMore = true;
      _mediaApprovalFilter = approvalFilter;
    } else if (!_mediaHasMore || _mediaLoading) {
      return;
    }

    _mediaLoading = true;
    notifyListeners();

    try {
      final result = await _service.getMyMedia(
        approvalStatus: _mediaApprovalFilter,
        page: _mediaPage,
      );
      if (refresh) {
        _media = result.content;
      } else {
        _media.addAll(result.content);
      }
      _mediaHasMore = !result.isLast;
      _mediaPage++;
    } catch (e) {
      debugPrint('❌ ChannelProvider.loadMedia: $e');
    } finally {
      _mediaLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    try {
      await _service.deleteMedia(mediaId);
      _media.removeWhere((m) => m.id == mediaId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ ChannelProvider.deleteMedia: $e');
      return false;
    }
  }

  // ── Upload ───────────────────────────────────────────────────────

  Future<bool> uploadMedia({
    required String title,
    String? description,
    required String mediaType,
    required List<int> mediaBytes,
    required String mediaFileName,
    List<int>? thumbnailBytes,
    String? thumbnailFileName,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    try {
      final uploaded = await _service.uploadMedia(
        title: title,
        description: description,
        mediaType: mediaType,
        mediaFilePath: mediaFileName, // used for content-type detection only
        mediaBytes: mediaBytes,
        mediaFileName: mediaFileName,
        thumbnailBytes: thumbnailBytes,
        thumbnailFileName: thumbnailFileName,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      // Prepend to the media list (newest first)
      _media.insert(0, uploaded);
      // Keep _uploadProgress = 1.0 so the screen can show 100% before navigating.
      // The screen must call resetUploadState() after popping.
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ ChannelProvider.uploadMedia: $e');
      _uploadError = e.toString();
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  /// Reset upload state.
  /// Call this BEFORE opening the upload screen (to clear any previous state)
  /// AND after a successful upload once the success UI has been shown.
  void resetUploadState() {
    _uploadProgress = 0.0;
    _isUploading = false;
    _uploadError = null;
    notifyListeners();
  }

  /// Reset provider state for sign-out. Clears all channel data so the next
  /// sign-in triggers a fresh initialization.
  void resetForSignOut() {
    _channel = null;
    _hasInitialized = false;
    _needsChannelSetup = false;
    _media = [];
    _mediaPage = 0;
    _mediaHasMore = true;
    _mediaApprovalFilter = null;
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadError = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
