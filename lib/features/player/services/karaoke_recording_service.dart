import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/models/media_item.dart';
import '../../channel/providers/channel_provider.dart';

/// The possible states of the karaoke recording flow.
enum KaraokeRecordingState {
  /// No recording in progress, ready to start.
  idle,

  /// Microphone is actively recording.
  recording,

  /// Recording has been stopped and a file is available.
  stopped,

  /// The recording is being uploaded as a reel.
  uploading,

  /// Upload completed successfully.
  done,

  /// An error occurred.
  error,
}

/// Karaoke Recording Service
///
/// Manages the full lifecycle of a karaoke cover recording:
/// 1. Start recording (mic only — song keeps playing via PlayerProvider)
/// 2. Stop recording → file saved locally
/// 3. Upload as a channel reel via ChannelProvider
///
/// Does NOT interact with or pause the PlayerProvider in any way.
class KaraokeRecordingService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();

  KaraokeRecordingState _state = KaraokeRecordingState.idle;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _errorMessage;
  bool _micBlockedUntilSettings = false;
  bool _starting = false;

  // ── Getters ──────────────────────────────────────────────────────

  KaraokeRecordingState get state => _state;
  String? get recordedFilePath => _recordedFilePath;
  Duration get recordingDuration => _recordingDuration;
  String? get errorMessage => _errorMessage;

  bool get isIdle => _state == KaraokeRecordingState.idle;
  bool get isRecording => _state == KaraokeRecordingState.recording;
  bool get isStopped => _state == KaraokeRecordingState.stopped;
  bool get isUploading => _state == KaraokeRecordingState.uploading;
  bool get isDone => _state == KaraokeRecordingState.done;
  bool get hasError => _state == KaraokeRecordingState.error;

  /// True when the mic was refused in a way only the Settings app can undo.
  bool get needsMicSettings => hasError && _micBlockedUntilSettings;

  /// Open this app's page in the system Settings app.
  Future<bool> openMicSettings() => openAppSettings();

  /// Whether the current platform supports recording.
  /// Web is not supported.
  bool get isPlatformSupported => !kIsWeb;

  /// Recording settings: AAC, good quality for voice.
  ///
  /// The per-platform configs are what keep the backing track alive while the
  /// mic is open — without them the recorder takes the audio route for itself
  /// and the song the user is singing along to goes silent:
  ///
  ///  * iOS: the recorder switches the shared AVAudioSession to
  ///    `playAndRecord` and activates it. Its default category options omit
  ///    `mixWithOthers`, so activation interrupts just_audio and playback stops
  ///    the instant recording starts. Adding `mixWithOthers` lets the two
  ///    coexist, which is the whole premise of karaoke.
  ///  * Android: `manageBluetooth` opens a Bluetooth SCO (call-audio) link on
  ///    paired headsets, which tears down the A2DP stream the music is playing
  ///    over. `mic` is the raw input — the default source applies voice
  ///    processing that can duck or cancel the backing track.
  static const RecordConfig recordConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    sampleRate: 44100,
    bitRate: 128000,
    numChannels: 1, // Mono for voice recording
    iosConfig: IosRecordConfig(
      categoryOptions: [
        IosAudioCategoryOption.mixWithOthers,
        IosAudioCategoryOption.defaultToSpeaker,
        IosAudioCategoryOption.allowBluetooth,
        IosAudioCategoryOption.allowBluetoothA2DP,
      ],
    ),
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.mic,
      manageBluetooth: false,
    ),
  );

  // ── Recording lifecycle ──────────────────────────────────────────

  /// Start recording the user's microphone audio.
  ///
  /// Returns `true` if recording started successfully.
  /// The song playback (managed by PlayerProvider) is NOT affected.
  Future<bool> startRecording() async {
    // Starting takes a moment (the permission prompt, audio session setup)
    // while the record button is still on screen. A second tap in that window
    // would open a second recording and a second duration timer.
    if (_starting || isRecording) return false;
    _starting = true;
    try {
      return await _startRecording();
    } finally {
      _starting = false;
    }
  }

  Future<bool> _startRecording() async {
    if (!isPlatformSupported) {
      _errorMessage = 'Recording is not supported on this platform';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }

    // Request microphone permission
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      // iOS shows its prompt once; after a single "Don't Allow" it reports
      // permanentlyDenied and never prompts again, so Settings is the only way
      // back. Restricted (parental controls) can't be lifted from there.
      _micBlockedUntilSettings = micPermission.isPermanentlyDenied;
      _errorMessage = micPermission.isRestricted
          ? 'Microphone access is restricted on this device'
          : _micBlockedUntilSettings
          ? 'Microphone access is off for Veena. Turn it on in Settings to record.'
          : 'Microphone permission is required to record';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }
    _micBlockedUntilSettings = false;

    // Check if recorder is available
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _errorMessage = 'Microphone access was denied';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }

    try {
      // Generate a unique file path in temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/karaoke_cover_$timestamp.m4a';

      await _recorder.start(recordConfig, path: filePath);

      _recordedFilePath = filePath;
      _recordingDuration = Duration.zero;
      _errorMessage = null;
      _state = KaraokeRecordingState.recording;

      // Start a timer to track duration
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ KaraokeRecordingService.startRecording: $e');
      _errorMessage = 'Failed to start recording: $e';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Stop the active recording.
  ///
  /// After calling this, [recordedFilePath] contains the path to the .m4a file
  /// and [recordingDuration] reflects the total length.
  Future<void> stopRecording() async {
    if (_state != KaraokeRecordingState.recording) return;

    _durationTimer?.cancel();
    _durationTimer = null;

    try {
      final path = await _recorder.stop();
      if (path != null) {
        _recordedFilePath = path;
      }
      await _restorePlaybackSession();
      _state = KaraokeRecordingState.stopped;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ KaraokeRecordingService.stopRecording: $e');
      _errorMessage = 'Failed to stop recording: $e';
      _state = KaraokeRecordingState.error;
      notifyListeners();
    }
  }

  /// Put the audio session back into music-playback mode.
  ///
  /// The recorder leaves the session on `playAndRecord` when it stops — it
  /// never restores the previous category — and that route is quieter than
  /// plain `playback`. Without this, every song played after a karaoke take
  /// stays at the reduced record-mode volume for the rest of the session.
  Future<void> _restorePlaybackSession() async {
    if (kIsWeb) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('KaraokeRecordingService._restorePlaybackSession: $e');
    }
  }

  /// Upload the recorded file as a reel to the user's channel.
  ///
  /// Uses [ChannelProvider.uploadMedia] under the hood.
  /// [sourceKaraokeItem] is the original karaoke song the user sang along to.
  Future<bool> uploadAsReel({
    required ChannelProvider channelProvider,
    required MediaItem sourceKaraokeItem,
    required String title,
    String? description,
  }) async {
    if (_recordedFilePath == null) {
      _errorMessage = 'No recording available to upload';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }

    _state = KaraokeRecordingState.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final bytes = await file.readAsBytes();
      final fileName =
          'karaoke_cover_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Build description that references the source karaoke track
      final finalDescription = description?.isNotEmpty == true
          ? description!
          : 'Karaoke cover of "${sourceKaraokeItem.title}" by ${sourceKaraokeItem.artistName}';

      final success = await channelProvider.uploadMedia(
        title: title,
        description: finalDescription,
        mediaType: 'AUDIO',
        mediaBytes: bytes,
        mediaFileName: fileName,
      );

      if (success) {
        _state = KaraokeRecordingState.done;
        notifyListeners();
        return true;
      } else {
        _errorMessage = channelProvider.uploadError ?? 'Upload failed';
        _state = KaraokeRecordingState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ KaraokeRecordingService.uploadAsReel: $e');
      _errorMessage = 'Upload failed: $e';
      _state = KaraokeRecordingState.error;
      notifyListeners();
      return false;
    }
  }

  /// Reset the service to idle state, cleaning up any temp files.
  void reset() {
    _durationTimer?.cancel();
    _durationTimer = null;

    // Clean up temp file if it exists
    if (_recordedFilePath != null) {
      try {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('KaraokeRecordingService.reset: cleanup error: $e');
      }
    }

    _state = KaraokeRecordingState.idle;
    _recordedFilePath = null;
    _recordingDuration = Duration.zero;
    _errorMessage = null;
    _micBlockedUntilSettings = false;
    notifyListeners();
  }

  /// Discard the current recording and go back to idle.
  void discard() => reset();

  /// Format a Duration as mm:ss.
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
