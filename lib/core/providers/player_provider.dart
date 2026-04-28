import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import '../models/media_item.dart' as app_models;
import '../models/lyrics_model.dart';
import '../services/lyrics_service.dart';
import '../services/media_service.dart';
import '../../../main.dart' show audioHandler;
import 'package:wakelock_plus/wakelock_plus.dart';

/// Repeat mode for playback
enum RepeatMode { off, all, one }

/// Player Provider
///
/// Centralized state management for media playback.
/// Supports both video and audio playback across all platforms.
/// Includes queue management for album/playlist playback.
class PlayerProvider extends ChangeNotifier {
  app_models.MediaItem? _currentMedia;
  VideoPlayerController? _videoController;
  MediaService? _mediaService;
  dynamic
  _authService; // Using dynamic to avoid circular import if necessary, or just import it

  Lyrics? _currentLyrics;
  final LyricsService _lyricsService = LyricsService();
  final _lyricIndexController = StreamController<int>.broadcast();
  int _lastLyricIndex = -1;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isMuted = false;

  // Queue management
  List<app_models.MediaItem> _queue = [];
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  List<int> _shuffledIndices = [];
  RepeatMode _repeatMode = RepeatMode.off;

  // Play operation lock to prevent duplicate concurrent plays
  int _activePlayOperations = 0;
  String? _lastPlayedMediaId;
  DateTime? _lastPlayRequestTime;

  // Throttle for position updates to prevent excessive rebuilds
  DateTime _lastPositionNotify = DateTime.now();

  // Getters
  app_models.MediaItem? get currentMedia => _currentMedia;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get hasMedia => _currentMedia != null;
  Lyrics? get currentLyrics => _currentLyrics;
  Stream<int> get lyricIndexStream => _lyricIndexController.stream;

  // Queue getters
  List<app_models.MediaItem> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get hasQueue => _queue.isNotEmpty;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  int get activeLyricIndex {
    if (_currentLyrics == null) return -1;
    return _currentLyrics!.getActiveLineIndex(_position);
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  VideoPlayerController? get videoController => _videoController;

  bool get isVideo => _currentMedia?.isVideo ?? false;
  bool get isAudio => _currentMedia?.isAudio ?? false;

  PlayerProvider() {
    _setupAudioListeners();
    _setupSkipCallbacks();
  }

  /// Wire notification bar skip controls to PlayerProvider
  void _setupSkipCallbacks() {
    final handler = audioHandler as dynamic;
    try {
      handler.onSkipToNext = () => next();
      handler.onSkipToPrevious = () => previous();
    } catch (e) {
      debugPrint('[PlayerProvider] Could not set skip callbacks: $e');
    }
  }

  /// Set the media service for auto play recording
  void setMediaService(MediaService service) {
    _mediaService = service;
  }

  /// Set the auth service for authenticated video requests
  void setAuthService(dynamic service) {
    _authService = service;
  }

  void _setupAudioListeners() {
    // Listen to playback state from AudioService
    audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == audio_service.AudioProcessingState.loading ||
          state.processingState == audio_service.AudioProcessingState.buffering;

      // Auto-advance to next track when current track completes
      // STRICT guard: only advance if we actually played most of the song
      if (state.processingState ==
          audio_service.AudioProcessingState.completed) {
        final hasValidDuration = _duration.inSeconds > 10;
        final hasPlayedMostOfSong =
            _position.inSeconds >= (_duration.inSeconds * 0.95).floor();
        final isActuallyNearEnd =
            _position.inSeconds >= _duration.inSeconds - 3;

        if (hasValidDuration && hasPlayedMostOfSong && isActuallyNearEnd) {
          debugPrint(
            '[PlayerProvider] Track completed - advancing (pos: ${_position.inSeconds}s, dur: ${_duration.inSeconds}s)',
          );
          _onTrackCompleted();
        } else {
          debugPrint(
            '[PlayerProvider] Ignoring premature completion signal (pos: ${_position.inSeconds}s, dur: ${_duration.inSeconds}s)',
          );
        }
      }

      _updateWakelock();
      notifyListeners();
    });

    // Listen to position updates directly from handler's player
    // Throttle to ~15fps to prevent excessive widget rebuilds
    final handler = audioHandler as dynamic;
    handler.positionStream.listen((Duration pos) {
      if (_currentMedia?.isAudio ?? false) {
        _position = pos;
        _updateLyricIndex();
        final now = DateTime.now();
        if (now.difference(_lastPositionNotify).inMilliseconds >= 64) {
          _lastPositionNotify = now;
          notifyListeners();
        }
      }
    });

    // Listen to media item (for duration)
    audioHandler.mediaItem.listen((item) {
      if (item?.duration != null) {
        _duration = item!.duration!;
        notifyListeners();
      }
    });
  }

  /// Called when current track completes - auto-advance based on repeat mode
  void _onTrackCompleted() {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Replay current track
        seek(Duration.zero);
        resume();
        break;
      case RepeatMode.all:
        // If at end, loop back to start
        if (hasNext) {
          next();
        } else if (_queue.isNotEmpty) {
          _currentIndex = 0;
          _playCurrentItem();
        }
        break;
      case RepeatMode.off:
        // Only advance if there's a next track
        if (hasNext) {
          next();
        }
        break;
    }
  }

  /// Toggle shuffle mode on/off
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    debugPrint('[PlayerProvider] Shuffle toggled: $_shuffleEnabled');

    if (_shuffleEnabled && _queue.isNotEmpty) {
      // Generate new shuffled indices when enabling shuffle
      _generateShuffledIndices();
    }
    notifyListeners();
  }

  /// Cycle through repeat modes: off -> all -> one -> off
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    debugPrint('[PlayerProvider] Repeat mode toggled: $_repeatMode');
    notifyListeners();
  }

  /// Play a single media item (clears queue)
  /// [startPosition] - Optional position to start playback from (for audio/video switching)
  Future<void> play(
    app_models.MediaItem media, {
    Duration? startPosition,
  }) async {
    // When playing single item, set up a queue with just this item
    _queue = [media];
    _currentIndex = 0;
    await _playCurrentItem(startPosition: startPosition);
  }

  /// Play a queue of media items starting from an index
  Future<void> playQueue(
    List<app_models.MediaItem> items, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (items.isEmpty) {
      debugPrint('[PlayerProvider] playQueue called with empty items');
      return;
    }

    debugPrint(
      '[PlayerProvider] playQueue: ${items.length} items, startIndex: $startIndex, shuffle: $shuffle',
    );

    _queue = List.from(items);
    _shuffleEnabled = shuffle;

    if (shuffle) {
      _generateShuffledIndices();
      _currentIndex = 0; // Start at first shuffled index
    } else {
      _currentIndex = startIndex.clamp(0, items.length - 1);
    }

    debugPrint(
      '[PlayerProvider] Queue set: ${_queue.length} items, currentIndex: $_currentIndex',
    );
    await _playCurrentItem();
  }

  /// Generate shuffled indices for shuffle mode
  void _generateShuffledIndices() {
    _shuffledIndices = List.generate(_queue.length, (i) => i);
    _shuffledIndices.shuffle();
  }

  /// Get the actual queue index (handles shuffle)
  int _getActualIndex(int index) {
    if (_shuffleEnabled && _shuffledIndices.isNotEmpty) {
      return _shuffledIndices[index];
    }
    return index;
  }

  int _getCurrentQueueIndex() {
    if (_queue.isEmpty || _currentIndex < 0) return -1;
    if (_shuffleEnabled &&
        _shuffledIndices.isNotEmpty &&
        _currentIndex < _shuffledIndices.length) {
      return _shuffledIndices[_currentIndex];
    }
    if (_currentIndex >= _queue.length) return _queue.length - 1;
    return _currentIndex;
  }

  /// Play the current item in the queue
  /// [startPosition] - Optional position to start playback from
  Future<void> _playCurrentItem({Duration? startPosition}) async {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) {
      return;
    }

    final actualIndex = _getActualIndex(_currentIndex);
    final media = _queue[actualIndex];

    // Debounce protection: prevent duplicate plays of the same media within 1 second
    final now = DateTime.now();
    if (_lastPlayedMediaId == media.id && _lastPlayRequestTime != null) {
      final timeSinceLastPlay = now
          .difference(_lastPlayRequestTime!)
          .inMilliseconds;
      if (timeSinceLastPlay < 1000) {
        debugPrint(
          '[PlayerProvider] BLOCKED duplicate play request for ${media.id} (${timeSinceLastPlay}ms ago)',
        );
        return;
      }
    }

    // Lock protection: prevent concurrent play operations for the SAME media
    // But allow if we are switching to a different track (User pressed Next/Prev)
    if (_activePlayOperations > 0 && _lastPlayedMediaId == media.id) {
      debugPrint(
        '[PlayerProvider] BLOCKED duplicate play request for ${media.id} - operation already in progress. Active ops: $_activePlayOperations',
      );
      return;
    }

    // Increment active operations counter
    _activePlayOperations++;
    _lastPlayedMediaId = media.id;
    _lastPlayRequestTime = now;

    if (media.hlsUrl == null || media.hlsUrl!.isEmpty) {
      debugPrint(
        '[PlayerProvider] No HLS URL available for media: ${media.id}',
      );
      _activePlayOperations--; // Release lock before trying next
      // Try next track
      if (hasNext) {
        _currentIndex++;
        await _playCurrentItem();
      }
      return;
    }

    // Clean up video controller if it exists
    if (_videoController != null) {
      final oldController = _videoController!;
      _videoController = null;
      oldController.removeListener(_onVideoUpdate);
      await oldController.dispose();
    }

    // Batch state update: set new media + loading in one notify
    _currentMedia = media;
    _isLoading = true;
    _currentLyrics = null;
    notifyListeners();

    // Auto-record play event for analytics (Fire-and-forget, non-blocking)
    debugPrint('[PlayerProvider] 📊 Analytics: Recording play for ${media.id}');
    _mediaService?.recordPlay(media.id);

    // Fetch lyrics if available
    if (media.lyricsUrl != null && media.lyricsUrl!.isNotEmpty) {
      _lyricsService.fetchLyrics(media.lyricsUrl!).then((lyrics) {
        _currentLyrics = lyrics;
        notifyListeners();
      });
    }

    try {
      if (media.isVideo) {
        await _playVideo(media.hlsUrl!, startPosition: startPosition);
      } else {
        await _playAudio(media, startPosition: startPosition);
      }
    } catch (e) {
      debugPrint('[PlayerProvider] Error playing media: $e');
      _isLoading = false;
      notifyListeners();
    } finally {
      // Release lock after play operation completes
      if (_activePlayOperations > 0) _activePlayOperations--;
    }
  }

  Future<void> _playVideo(String url, {Duration? startPosition}) async {
    // Stop audio playback but keep notification capability
    await audioHandler.stop();

    // Set up audio service notification for video (enables lock screen controls)
    if (_currentMedia != null) {
      final item = audio_service.MediaItem(
        id: _currentMedia!.id,
        album: _currentMedia!.artistName,
        title: _currentMedia!.title,
        artist: _currentMedia!.artistName,
        artUri: _currentMedia!.thumbnailUrl != null
            ? Uri.parse(_currentMedia!.thumbnailUrl!)
            : null,
        duration: Duration.zero, // Will update after video initializes
      );
      await audioHandler.updateMediaItem(item);
    }

    // Clean up video controller if it exists
    if (_videoController != null) {
      final oldController = _videoController!;
      _videoController = null;
      notifyListeners();
      oldController.removeListener(_onVideoUpdate);
      await oldController.dispose();
    }

    // Ensure URL is absolute (relative to ApiService.baseUrl if needed)
    String finalizedUrl = url;
    if (!url.startsWith('http')) {
      const apiPrefix = 'https://veena.dgfly.in/api';
      final rootUrl = apiPrefix.replaceFirst('/api', '');
      finalizedUrl = url.startsWith('/') ? '$rootUrl$url' : '$rootUrl/$url';
    }

    // Get auth token if available
    final token = _authService?.accessToken;
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    debugPrint(
      '[PlayerProvider] Initializing video with headers: ${headers.keys}',
    );

    // Use network video for HLS
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(finalizedUrl),
      httpHeaders: headers,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );

    try {
      await _videoController!.initialize().timeout(const Duration(seconds: 15));
      _duration = _videoController!.value.duration;
    } catch (e) {
      debugPrint('[PlayerProvider] Video initialization failed: $e');
      _isLoading = false;
      _videoController = null;
      notifyListeners();
      return;
    }

    // Seek to start position if provided (for audio/video switching)
    if (startPosition != null && startPosition > Duration.zero) {
      await _videoController!.seekTo(startPosition);
      debugPrint(
        '[PlayerProvider] Seeking video to: ${startPosition.inSeconds}s',
      );
    }

    // Update notification with actual duration
    if (_currentMedia != null) {
      final itemWithDuration = audio_service.MediaItem(
        id: _currentMedia!.id,
        album: _currentMedia!.artistName,
        title: _currentMedia!.title,
        artist: _currentMedia!.artistName,
        artUri: _currentMedia!.thumbnailUrl != null
            ? Uri.parse(_currentMedia!.thumbnailUrl!)
            : null,
        duration: _duration,
      );
      await audioHandler.updateMediaItem(itemWithDuration);
    }

    // Listen to video position
    _videoController!.addListener(_onVideoUpdate);

    await _videoController!.setVolume(_isMuted ? 0.0 : _volume);

    if (!kIsWeb) {
      try {
        await _videoController!.play();
        _isPlaying = true;
      } catch (e) {
        debugPrint('[PlayerProvider] Video play() failed: $e');
        _isPlaying = false;
      }
    } else {
      debugPrint(
        '[PlayerProvider] Web: Skipping auto-play, waiting for user interaction',
      );
      _isPlaying = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _onVideoUpdate() {
    if (_videoController != null) {
      _position = _videoController!.value.position;
      _isPlaying = _videoController!.value.isPlaying;
      _isLoading = _videoController!.value.isBuffering;

      // Check for video completion
      if (_videoController!.value.position >=
              _videoController!.value.duration &&
          _videoController!.value.duration.inMilliseconds > 0) {
        _onTrackCompleted();
      }

      _updateWakelock();
      _updateLyricIndex();
      notifyListeners();
    }
  }

  Future<void> _playAudio(
    app_models.MediaItem media, {
    Duration? startPosition,
  }) async {
    // Create audio_service MediaItem for notification
    final item = audio_service.MediaItem(
      id: media.id,
      album: media.artistName,
      title: media.title,
      artist: media.artistName,
      duration: null, // Will be updated when loaded
      artUri: media.thumbnailUrl != null
          ? Uri.parse(media.thumbnailUrl!)
          : null,
      extras: {'url': media.hlsUrl},
    );

    // Set media item for notification (cast to our handler type)
    (audioHandler as dynamic).setMediaItem(item);

    // Load audio URL (does NOT auto-play anymore)
    await audioHandler.playFromUri(Uri.parse(media.hlsUrl!));

    // Seek to position BEFORE playing (for audio/video switching)
    if (startPosition != null && startPosition > Duration.zero) {
      debugPrint(
        '[PlayerProvider] Seeking audio to: ${startPosition.inSeconds}s BEFORE play',
      );
      await audioHandler.seek(startPosition);
      debugPrint('[PlayerProvider] Audio seeked, now starting playback');
    }

    // NOW start playback from the seeked position
    // Apply current volume/mute state to audio handler (esp. for web)
    try {
      await audioHandler.customAction('setVolume', {
        'volume': _isMuted ? 0.0 : _volume,
      });
    } catch (e) {
      debugPrint('[PlayerProvider] Error applying volume to audio handler: $e');
    }

    await audioHandler.play();
    debugPrint('[PlayerProvider] Audio playback started');

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_currentMedia?.isVideo ?? false) {
      await _videoController?.pause();
    } else {
      await audioHandler.pause();
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_currentMedia?.isVideo ?? false) {
      await _videoController?.play();
    } else {
      await audioHandler.play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }

    await audioHandler.stop();

    _isPlaying = false;
    _position = Duration.zero;
    _currentLyrics = null;
    _updateWakelock();
    notifyListeners();
  }

  /// Clear queue and stop playback
  Future<void> clearQueue() async {
    await stop();
    _queue = [];
    _currentIndex = -1;
    _currentMedia = null;
    _updateWakelock();
    notifyListeners();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_currentMedia?.isVideo ?? false) {
      await _videoController?.seekTo(position);
    } else {
      await audioHandler.seek(position);
    }
    _position = position;
    notifyListeners();
  }

  /// Seek to progress (0.0 to 1.0)
  Future<void> seekToProgress(double progress) async {
    final newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    await seek(newPosition);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_currentMedia?.isVideo ?? false) {
      await _videoController?.setVolume(_volume);
    } else {
      // Send volume to audio handler for web support
      try {
        await audioHandler.customAction('setVolume', {'volume': _volume});
      } catch (e) {
        debugPrint('[PlayerProvider] Error setting volume: $e');
      }
    }
    notifyListeners();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await setVolume(_isMuted ? 0.0 : 1.0);
  }

  /// Skip to next item in queue
  Future<void> next() async {
    debugPrint(
      '[PlayerProvider] next() called - queue: ${_queue.length}, currentIndex: $_currentIndex, hasNext: $hasNext',
    );
    if (!hasNext) {
      debugPrint('[PlayerProvider] No next track available');
      return;
    }

    _currentIndex++;
    await _playCurrentItem();
  }

  /// Skip to previous item in queue
  Future<void> previous() async {
    // If more than 3 seconds in, restart current track
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (!hasPrevious) {
      await seek(Duration.zero);
      return;
    }

    _currentIndex--;
    await _playCurrentItem();
  }

  /// Play specific track from queue by index
  Future<void> playQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrentItem();
  }

  /// Remove an item from now-playing queue by queue index.
  /// Returns true when an item is removed, false for invalid index.
  Future<bool> removeFromQueueAt(int index) async {
    if (index < 0 || index >= _queue.length) return false;

    final currentQueueIndex = _getCurrentQueueIndex();
    final removingCurrent = index == currentQueueIndex;
    final activeMediaId = _currentMedia?.id;

    _queue.removeAt(index);

    if (_queue.isEmpty) {
      await clearQueue();
      return true;
    }

    if (_shuffleEnabled) {
      _generateShuffledIndices();

      if (!removingCurrent && activeMediaId != null) {
        final activeQueueIndex = _queue.indexWhere(
          (m) => m.id == activeMediaId,
        );
        if (activeQueueIndex != -1) {
          final shuffledPosition = _shuffledIndices.indexOf(activeQueueIndex);
          if (shuffledPosition != -1) {
            _currentIndex = shuffledPosition;
            notifyListeners();
            return true;
          }
        }
      }

      if (removingCurrent) {
        final nextQueueIndex = index >= _queue.length
            ? _queue.length - 1
            : index;
        final nextShuffledPosition = _shuffledIndices.indexOf(nextQueueIndex);
        _currentIndex = nextShuffledPosition == -1 ? 0 : nextShuffledPosition;
        _lastPlayedMediaId = null; // allow immediate replay of same media id
        await _playCurrentItem();
        return true;
      }

      _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
      notifyListeners();
      return true;
    }

    // Removed item is before current item: shift current index left.
    if (!removingCurrent) {
      if (currentQueueIndex != -1 && index < currentQueueIndex) {
        _currentIndex = currentQueueIndex - 1;
      }
      notifyListeners();
      return true;
    }

    // Removed currently playing item: continue from same position if possible.
    _currentIndex = index >= _queue.length ? _queue.length - 1 : index;
    _lastPlayedMediaId = null; // allow immediate replay of same media id
    await _playCurrentItem();
    return true;
  }

  Future<bool> removeFromQueueById(String mediaId) async {
    final index = _queue.indexWhere((m) => m.id == mediaId);
    if (index == -1) return false;
    return removeFromQueueAt(index);
  }

  /// Format duration to string
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateLyricIndex() {
    if (_currentLyrics != null) {
      final index = _currentLyrics!.getActiveLineIndex(_position);
      if (index != _lastLyricIndex) {
        _lastLyricIndex = index;
        _lyricIndexController.add(index);
      }
    }
  }

  void _updateWakelock() {
    try {
      if (_isPlaying && isVideo) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('[PlayerProvider] Wakelock error: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _lyricIndexController.close();
    WakelockPlus.disable();
    super.dispose();
  }
}
