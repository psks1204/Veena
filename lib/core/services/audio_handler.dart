import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Veena Audio Handler
///
/// Manages background audio playback and notification/lock screen controls.
class VeenaAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  late final Stream<Duration> _positionStream = _player.createPositionStream(
    minPeriod: const Duration(milliseconds: 200),
    maxPeriod: const Duration(milliseconds: 200),
  );

  // Callbacks for skip controls from notification bar
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  // Our own mediaItem subject since we're not using the queue system
  final BehaviorSubject<MediaItem?> _mediaItemSubject = BehaviorSubject.seeded(
    null,
  );

  VeenaAudioHandler() {
    _init();
  }

  @override
  BehaviorSubject<MediaItem?> get mediaItem => _mediaItemSubject;

  /// Get the position stream for UI updates
  Stream<Duration> get positionStream => _positionStream;

  /// Get the current duration
  Duration? get currentDuration => _player.duration;

  Future<void> _init() async {
    // Listen to playback events and broadcast them to AudioService
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (e) {
        debugPrint('VeenaAudioHandler: playbackEventStream error: $e');
      },
    );

    // Listen to duration changes and update mediaItem
    _player.durationStream.listen((duration) {
      if (duration != null && _mediaItemSubject.value != null) {
        final updatedItem = _mediaItemSubject.value!.copyWith(
          duration: duration,
        );
        _mediaItemSubject.add(updatedItem);
      }
    });

    // NOTE: Removed automatic stop() on ProcessingState.completed
    // The PlayerProvider will handle track completion based on position/duration checks
    // This prevents premature track skipping with HLS streams
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
    debugPrint('VeenaAudioHandler: setUrl done (not auto-playing)');
    // NOTE: We don't call play() here anymore - caller will seek then play
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('VeenaAudioHandler: skipToNext called');
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('VeenaAudioHandler: skipToPrevious called');
    onSkipToPrevious?.call();
  }

  // --- Broadcast State Helpers ---

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
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
      ),
    );
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'setVolume') {
      final volume = extras?['volume'] as double?;
      if (volume != null) {
        await _player.setVolume(volume);
      }
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
}
