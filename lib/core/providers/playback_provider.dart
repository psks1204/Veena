import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../shared/models/media_item.dart';
import '../services/playback_service.dart';
import '../services/media_service.dart';
import '../../features/auth/services/auth_service.dart';

enum PlaybackType { none, audio, video }
enum RepeatMode { off, all, one }

class PlaybackProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaybackService _playbackService = PlaybackService();
  final MediaService _mediaService = MediaService();
  VideoPlayerController? _videoController;
  AuthService? _authService;

  MediaItem? _currentMedia;
  PlaybackType _currentType = PlaybackType.none;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Queue management
  List<MediaItem> _queue = [];
  int _currentIndex = -1;
  bool _isShuffleOn = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Lyrics
  String? _currentLyrics;
  bool _isLoadingLyrics = false;

  // Getters
  MediaItem? get currentMedia => _currentMedia;
  PlaybackType get currentType => _currentType;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  VideoPlayerController? get videoController => _videoController;
  bool get isShuffleOn => _isShuffleOn;
  RepeatMode get repeatMode => _repeatMode;
  List<MediaItem> get queue => _queue;
  String? get currentLyrics => _currentLyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;

  void updateAuth(AuthService auth) {
    _authService = auth;
  }

  PlaybackProvider() {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleMediaCompleted();
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      debugPrint('Audio Error: $e');
    });
  }

  void _handleMediaCompleted() {
    if (_repeatMode == RepeatMode.one) {
      seek(Duration.zero);
      togglePlay();
    } else {
      next();
    }
  }

  void setQueue(List<MediaItem> items, {int initialStateIndex = 0}) {
    _queue = List.from(items);
    if (items.isNotEmpty) {
      if (initialStateIndex >= 0 && initialStateIndex < items.length) {
        _currentIndex = initialStateIndex;
        playMedia(items[initialStateIndex]);
      }
    }
  }

  Future<void> playMedia(MediaItem media) async {
    // If media is not in queue, add it
    if (!_queue.contains(media)) {
      _queue.insert(_currentIndex + 1, media);
      _currentIndex++;
    } else {
      _currentIndex = _queue.indexOf(media);
    }

    // Stop current playback (but don't clear queue)
    await stop(clearQueue: false);

    _currentMedia = media;
    final url = media.hlsUrl;
    if (url == null) return;

    if (media.mediaType == 'VIDEO') {
      _currentType = PlaybackType.video;
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      
      try {
        await _videoController!.initialize();
        _videoController!.addListener(_videoListener);
        await _videoController!.play();
        _isPlaying = true;
      } catch (e) {
        debugPrint('Error loading video: $e');
      }
    } else {
      _currentType = PlaybackType.audio;
      try {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
        await _audioPlayer.play();
        _isPlaying = true;
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }

    // Record play on backend
    if (_authService != null) {
      _playbackService.recordPlay(
        media.id,
        token: _authService!.token,
      );
      // Fetch like status from backend
      fetchLikeStatus();
    }

    // Load lyrics if available
    loadLyrics();

    notifyListeners();
  }

  void _videoListener() {
    if (_videoController == null) return;
    _position = _videoController!.value.position;
    _duration = _videoController!.value.duration;
    _isPlaying = _videoController!.value.isPlaying;
    
    // Check for completion
    if (_videoController!.value.position >= _videoController!.value.duration && 
        _videoController!.value.duration > Duration.zero &&
        !_videoController!.value.isPlaying) {
        _handleMediaCompleted();
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_currentType == PlaybackType.audio) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } else if (_currentType == PlaybackType.video && _videoController != null) {
      if (_isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
    }
  }

  Future<void> seek(Duration position) async {
    if (_currentType == PlaybackType.audio) {
      await _audioPlayer.seek(position);
    } else if (_currentType == PlaybackType.video && _videoController != null) {
      await _videoController!.seekTo(position);
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    
    if (_isShuffleOn) {
      _currentIndex = (DateTime.now().millisecondsSinceEpoch) % _queue.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
      if (_currentIndex == 0 && _repeatMode == RepeatMode.off) {
        await stop();
        return;
      }
    }
    
    await playMedia(_queue[_currentIndex]);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1);
    if (_currentIndex < 0) {
      _currentIndex = _queue.length - 1;
    }
    
    await playMedia(_queue[_currentIndex]);
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  Future<void> stop({bool clearQueue = true}) async {
    if (_currentType == PlaybackType.audio) {
      await _audioPlayer.stop();
    } else if (_currentType == PlaybackType.video && _videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }
    
    _isPlaying = false;
    _currentType = PlaybackType.none;
    _currentMedia = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentLyrics = null;

    if (clearQueue) {
      _queue = [];
      _currentIndex = -1;
    }
    notifyListeners();
  }

  /// Toggle like status for current media
  Future<void> toggleLike() async {
    if (_currentMedia == null || _authService == null) return;

    try {
      final response = await _mediaService.toggleLike(
        _currentMedia!.id,
        token: _authService!.token,
      );

      // Update current media like status
      _currentMedia!.isLiked = response.liked;
      _currentMedia!.likeCount = response.likeCount;

      // Update in queue as well
      final queueIndex = _queue.indexWhere((m) => m.id == _currentMedia!.id);
      if (queueIndex != -1) {
        _queue[queueIndex].isLiked = response.liked;
        _queue[queueIndex].likeCount = response.likeCount;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  /// Load lyrics for current media
  Future<void> loadLyrics() async {
    if (_currentMedia == null || _currentMedia!.lyricsUrl == null) {
      _currentLyrics = null;
      return;
    }

    _isLoadingLyrics = true;
    notifyListeners();

    try {
      _currentLyrics = await _mediaService.fetchLyrics(_currentMedia!.lyricsUrl!);
    } catch (e) {
      debugPrint('Error loading lyrics: $e');
      _currentLyrics = null;
    } finally {
      _isLoadingLyrics = false;
      notifyListeners();
    }
  }

  /// Fetch like status for current media from backend
  Future<void> fetchLikeStatus() async {
    if (_currentMedia == null || _authService == null) return;

    try {
      final response = await _mediaService.getLikeStatus(
        _currentMedia!.id,
        token: _authService!.token,
      );
      _currentMedia!.isLiked = response.liked;
      _currentMedia!.likeCount = response.likeCount;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching like status: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}
