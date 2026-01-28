import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import '../models/media_item.dart' as app_models;
import '../models/lyrics_model.dart';
import '../services/lyrics_service.dart';
import '../services/media_service.dart';
import '../../../main.dart' show audioHandler;

/// Player Provider
/// 
/// Centralized state management for media playback.
/// Supports both video and audio playback across all platforms.
class PlayerProvider extends ChangeNotifier {
  app_models.MediaItem? _currentMedia;
  VideoPlayerController? _videoController;
  MediaService? _mediaService;
  
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

  int get activeLyricIndex {
    if (_currentLyrics == null) return -1;
    return _currentLyrics!.getActiveLineIndex(_position);
  }
  
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }
  
  VideoPlayerController? get videoController => _videoController;
  
  bool get isVideo => _currentMedia?.isVideo ?? false;
  bool get isAudio => _currentMedia?.isAudio ?? false;

  PlayerProvider() {
    _setupAudioListeners();
  }
  
  /// Set the media service for auto play recording
  void setMediaService(MediaService service) {
    _mediaService = service;
  }

  void _setupAudioListeners() {
    // Listen to playback state from AudioService
    audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == audio_service.AudioProcessingState.loading ||
                   state.processingState == audio_service.AudioProcessingState.buffering;
      notifyListeners();
    });

    // Listen to position updates directly from handler's player
    final handler = audioHandler as dynamic;
    handler.positionStream.listen((Duration pos) {
      if (_currentMedia?.isAudio ?? false) {
        _position = pos;
        _updateLyricIndex();
        notifyListeners();
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

  /// Play a media item
  Future<void> play(app_models.MediaItem media) async {
    if (media.hlsUrl == null || media.hlsUrl!.isEmpty) {
      debugPrint('[PlayerProvider] No HLS URL available for media: ${media.id}');
      return;
    }

    // Clean up video controller if it exists
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }

    _currentMedia = media;
    _isLoading = true;
    _currentLyrics = null;
    notifyListeners();
    
    // Auto-record play event for analytics
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
        await _playVideo(media.hlsUrl!);
      } else {
        await _playAudio(media);
      }
    } catch (e) {
      debugPrint('[PlayerProvider] Error playing media: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _playVideo(String url) async {
    // Stop audio if playing
    await audioHandler.stop();
    
    // Use network video for HLS
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );

    await _videoController!.initialize();
    _duration = _videoController!.value.duration;
    
    // Listen to video position
    _videoController!.addListener(_onVideoUpdate);
    
    await _videoController!.play();
    _isPlaying = true;
    _isLoading = false;
    notifyListeners();
  }

  void _onVideoUpdate() {
    if (_videoController != null) {
      _position = _videoController!.value.position;
      _isPlaying = _videoController!.value.isPlaying;
      _isLoading = _videoController!.value.isBuffering;
      _updateLyricIndex();
      notifyListeners();
    }
  }

  Future<void> _playAudio(app_models.MediaItem media) async {
    // Create audio_service MediaItem for notification
    final item = audio_service.MediaItem(
      id: media.id,
      album: media.artistName ?? 'Unknown Album',
      title: media.title,
      artist: media.artistName ?? 'Unknown Artist',
      duration: null, // Will be updated when loaded
      artUri: media.thumbnailUrl != null ? Uri.parse(media.thumbnailUrl!) : null,
      extras: {'url': media.hlsUrl},
    );
    
    // Set media item for notification (cast to our handler type)
    (audioHandler as dynamic).setMediaItem(item);
    
    // Play from URI
    await audioHandler.playFromUri(Uri.parse(media.hlsUrl!));
    
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
    }
    // Note: AudioService volume is controlled by system
    notifyListeners();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await setVolume(_isMuted ? 0.0 : 1.0);
  }

  /// Skip to next item
  Future<void> next() async {
    await audioHandler.skipToNext();
    notifyListeners();
  }

  /// Skip to previous item
  Future<void> previous() async {
    await audioHandler.skipToPrevious();
    notifyListeners();
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

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _lyricIndexController.close();
    super.dispose();
  }
}
