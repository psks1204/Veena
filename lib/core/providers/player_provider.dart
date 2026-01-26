import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';
import '../models/lyrics_model.dart';
import '../services/lyrics_service.dart';

/// Player Provider
/// 
/// Centralized state management for media playback.
/// Supports both video and audio playback across all platforms.
class PlayerProvider extends ChangeNotifier {
  MediaItem? _currentMedia;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  
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
  MediaItem? get currentMedia => _currentMedia;
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
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer?.positionStream.listen((pos) {
      _position = pos;
      _updateLyricIndex();
      notifyListeners();
    });

    _audioPlayer?.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _audioPlayer?.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
      
      if (_currentLyrics != null) {
        final index = _currentLyrics!.getActiveLineIndex(_position);
        if (index != _lastLyricIndex) {
          _lastLyricIndex = index;
          _lyricIndexController.add(index);
        }
      }
      notifyListeners();
    });
  }

  /// Play a media item
  Future<void> play(MediaItem media) async {
    if (media.hlsUrl == null || media.hlsUrl!.isEmpty) {
      debugPrint('No HLS URL available for media: ${media.id}');
      return;
    }

    // Stop current playback
    await stop();

    _currentMedia = media;
    _isLoading = true;
    _currentLyrics = null; // Reset lyrics
    notifyListeners();

    // Fetch lyrics if available
    if (media.lyricsUrl != null && media.lyricsUrl!.isNotEmpty) {
      debugPrint('Fetching lyrics from: ${media.lyricsUrl}');
      _lyricsService.fetchLyrics(media.lyricsUrl!).then((lyrics) {
        if (lyrics != null) {
          debugPrint('Successfully fetched and parsed ${lyrics.lines.length} lyrics');
        } else {
          debugPrint('Failed to fetch or parse lyrics');
        }
        _currentLyrics = lyrics;
        notifyListeners();
      });
    } else {
      debugPrint('No lyricsUrl provided for this media item');
    }

    try {
      if (media.isVideo) {
        await _playVideo(media.hlsUrl!);
      } else {
        await _playAudio(media.hlsUrl!);
      }
    } catch (e) {
      debugPrint('Error playing media: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _playVideo(String url) async {
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

  Future<void> _playAudio(String url) async {
    await _audioPlayer?.setUrl(url);
    await _audioPlayer?.play();
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
      await _audioPlayer?.pause();
    }
    _isPlaying = false;
    notifyListeners();
  }

  /// Resume playback
  Future<void> resume() async {
    if (_currentMedia?.isVideo ?? false) {
      await _videoController?.play();
    } else {
      await _audioPlayer?.play();
    }
    _isPlaying = true;
    notifyListeners();
  }

  /// Stop playback
  Future<void> stop() async {
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }
    
    await _audioPlayer?.stop();
    
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
      await _audioPlayer?.seek(position);
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
      await _audioPlayer?.setVolume(_volume);
    }
    notifyListeners();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await setVolume(_isMuted ? 0.0 : 1.0);
  }

  /// Skip to next item (Stub)
  Future<void> next() async {
    // TODO: Implement queue system
    notifyListeners();
  }

  /// Skip to previous item (Stub)
  Future<void> previous() async {
    // TODO: Implement queue system
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
    _audioPlayer?.dispose();
    _lyricIndexController.close();
    super.dispose();
  }
}
