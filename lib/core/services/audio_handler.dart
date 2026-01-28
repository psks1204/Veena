import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Veena Audio Handler
/// 
/// Manages background audio playback and notification/lock screen controls.
class VeenaAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  
  // Our own mediaItem subject since we're not using the queue system
  final BehaviorSubject<MediaItem?> _mediaItemSubject = BehaviorSubject.seeded(null);

  VeenaAudioHandler() {
    _init();
  }

  @override
  BehaviorSubject<MediaItem?> get mediaItem => _mediaItemSubject;

  /// Get the position stream for UI updates
  Stream<Duration> get positionStream => _player.positionStream;
  
  /// Get the current duration
  Duration? get currentDuration => _player.duration;

  Future<void> _init() async {
    // Listen to playback events and broadcast them to AudioService
    _player.playbackEventStream.listen(_broadcastState, onError: (e) {
      debugPrint('VeenaAudioHandler: playbackEventStream error: $e');
    });
    
    // Listen to duration changes and update mediaItem
    _player.durationStream.listen((duration) {
      if (duration != null && _mediaItemSubject.value != null) {
        final updatedItem = _mediaItemSubject.value!.copyWith(duration: duration);
        _mediaItemSubject.add(updatedItem);
      }
    });
    
    // Listen to processing state for completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// Set the current media item for notification display
  void setMediaItem(MediaItem item) {
    _mediaItemSubject.add(item);
  }

  // --- External Control Methods ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    debugPrint('VeenaAudioHandler: playFromUri called with $uri');
    await _player.setUrl(uri.toString());
    debugPrint('VeenaAudioHandler: setUrl done, calling play');
    await _player.play();
    debugPrint('VeenaAudioHandler: play started successfully');
  }

  @override
  Future<void> skipToNext() async {
    // Stub - no queue implementation yet
    debugPrint('VeenaAudioHandler: skipToNext called (no queue)');
  }

  @override
  Future<void> skipToPrevious() async {
    // Stub - no queue implementation yet  
    debugPrint('VeenaAudioHandler: skipToPrevious called (no queue)');
  }

  // --- Broadcast State Helpers ---

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
}
