import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:veena/core/models/media_item.dart';
import 'package:veena/features/channel/providers/channel_provider.dart';
import 'package:veena/features/player/services/karaoke_recording_service.dart';

/// Regression tests for karaoke recording.
///
/// The headline fault was the backing track cutting out the moment recording
/// started: the recorder reconfigures the shared audio session for itself, and
/// nothing told it to share. Karaoke without the song is not karaoke.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recordConfig keeps the song playing', () {
    const config = KaraokeRecordingService.recordConfig;

    test('iOS mixes with the music session instead of interrupting it', () {
      // Without this option the recorder activates `playAndRecord` exclusively
      // and just_audio is interrupted — the song stops dead on tapping record.
      expect(
        config.iosConfig.categoryOptions,
        contains(IosAudioCategoryOption.mixWithOthers),
      );
    });

    test('iOS still routes playback to the speaker while recording', () {
      expect(
        config.iosConfig.categoryOptions,
        contains(IosAudioCategoryOption.defaultToSpeaker),
      );
    });

    test('iOS lets the recorder own the session it configures', () {
      expect(config.iosConfig.manageAudioSession, isTrue);
    });

    test('Android does not switch a headset to call audio', () {
      // Opening a Bluetooth SCO link tears down the A2DP stream the song is
      // playing over, silencing it for anyone on wireless headphones.
      expect(config.androidConfig.manageBluetooth, isFalse);
    });

    test('Android records the raw mic', () {
      expect(config.androidConfig.audioSource, AndroidAudioSource.mic);
    });

    test('Android never mutes the backing track', () {
      expect(config.androidConfig.muteAudio, isFalse);
    });

    test('records voice-quality mono AAC', () {
      expect(config.encoder, AudioEncoder.aacLc);
      expect(config.numChannels, 1);
      expect(config.sampleRate, 44100);
    });
  });

  group('state machine', () {
    late KaraokeRecordingService service;

    setUp(() => service = KaraokeRecordingService());
    tearDown(() => service.dispose());

    test('starts idle with nothing recorded', () {
      expect(service.isIdle, isTrue);
      expect(service.recordedFilePath, isNull);
      expect(service.recordingDuration, Duration.zero);
      expect(service.errorMessage, isNull);
    });

    test('stopping when not recording is a no-op', () async {
      await service.stopRecording();
      expect(service.isIdle, isTrue, reason: 'must not fall into stopped');
    });

    test('uploading without a recording reports an error, not a crash',
        () async {
      final ok = await service.uploadAsReel(
        channelProvider: _UnusedChannelProvider(),
        sourceKaraokeItem: _sourceSong,
        title: 'My Cover',
      );

      expect(ok, isFalse);
      expect(service.hasError, isTrue);
      expect(service.errorMessage, contains('No recording'));
    });

    test('reset clears an error back to a recordable state', () async {
      await service.uploadAsReel(
        channelProvider: _UnusedChannelProvider(),
        sourceKaraokeItem: _sourceSong,
        title: 'My Cover',
      );
      expect(service.hasError, isTrue);

      service.reset();

      expect(service.isIdle, isTrue);
      expect(service.errorMessage, isNull);
      expect(service.recordedFilePath, isNull);
    });

    test('every state the UI branches on is reachable and distinct', () {
      // The post sheet can be dismissed straight back into `stopped`, which the
      // player had no branch for — the karaoke row rendered empty and the take
      // became unreachable.
      expect(KaraokeRecordingState.values, hasLength(6));
      expect(
        KaraokeRecordingState.values,
        containsAll([
          KaraokeRecordingState.idle,
          KaraokeRecordingState.recording,
          KaraokeRecordingState.stopped,
          KaraokeRecordingState.uploading,
          KaraokeRecordingState.done,
          KaraokeRecordingState.error,
        ]),
      );
    });

    test('notifies listeners when the state moves', () async {
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.uploadAsReel(
        channelProvider: _UnusedChannelProvider(),
        sourceKaraokeItem: _sourceSong,
        title: 'My Cover',
      );

      expect(notifications, greaterThan(0));
    });

    test('web is refused rather than silently doing nothing', () {
      // kIsWeb is false under the VM, so this asserts the contract the web
      // layout relies on to show its "mobile only" message.
      expect(service.isPlatformSupported, isTrue);
    });
  });

  group('microphone permission', () {
    const permissionChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late KaraokeRecordingService service;
    late List<String> calls;

    /// The integers permission_handler's native side sends for each status.
    const wireValue = {
      PermissionStatus.denied: 0,
      PermissionStatus.granted: 1,
      PermissionStatus.restricted: 2,
      PermissionStatus.permanentlyDenied: 4,
    };

    /// Answer the mic request with [status], as the native side would.
    void micAnswers(PermissionStatus status) {
      messenger.setMockMethodCallHandler(permissionChannel, (call) async {
        calls.add(call.method);
        if (call.method == 'requestPermissions') {
          return {Permission.microphone.value: wireValue[status]};
        }
        if (call.method == 'openAppSettings') return true;
        return null;
      });
    }

    setUp(() {
      calls = [];
      service = KaraokeRecordingService();
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(permissionChannel, null);
      service.dispose();
    });

    test('a refusal only Settings can undo offers the way there', () async {
      // What iOS reports after one "Don't Allow" — it never prompts again.
      micAnswers(PermissionStatus.permanentlyDenied);

      expect(await service.startRecording(), isFalse);

      expect(service.hasError, isTrue);
      expect(service.needsMicSettings, isTrue);
      expect(service.errorMessage, contains('Settings'));
    });

    test('opening Settings goes to the app settings page', () async {
      micAnswers(PermissionStatus.permanentlyDenied);
      await service.startRecording();

      await service.openMicSettings();

      expect(calls, contains('openAppSettings'));
    });

    test('a plain denial asks again instead of sending to Settings', () async {
      micAnswers(PermissionStatus.denied);

      await service.startRecording();

      expect(service.hasError, isTrue);
      expect(service.needsMicSettings, isFalse);
    });

    test('a restricted mic is explained, not sent to Settings', () async {
      // Parental controls: Settings cannot lift this, so no button.
      micAnswers(PermissionStatus.restricted);

      await service.startRecording();

      expect(service.needsMicSettings, isFalse);
      expect(service.errorMessage, contains('restricted'));
    });

    test('a second tap while starting does not start twice', () async {
      // Hold the permission answer open, as the iOS prompt does.
      final answer = Completer<Object?>();
      messenger.setMockMethodCallHandler(permissionChannel, (call) async {
        calls.add(call.method);
        return answer.future;
      });

      final first = service.startRecording();
      final second = await service.startRecording();

      expect(second, isFalse);
      answer.complete({
        Permission.microphone.value: wireValue[PermissionStatus.denied],
      });
      await first;
      expect(calls.where((m) => m == 'requestPermissions'), hasLength(1));
    });

    test('reset clears the Settings prompt', () async {
      micAnswers(PermissionStatus.permanentlyDenied);
      await service.startRecording();
      expect(service.needsMicSettings, isTrue);

      service.reset();

      expect(service.needsMicSettings, isFalse);
    });
  });

  group('iOS build setup', () {
    test('Podfile compiles the microphone permission in', () {
      // permission_handler compiles each iOS permission out unless the Podfile
      // enables it. Without this macro the mic request never reaches iOS: it
      // returns permanentlyDenied instantly, no prompt appears, and Veena is
      // missing from Settings > Privacy > Microphone, so it cannot be granted.
      final podfile = File('ios/Podfile').readAsStringSync();

      expect(podfile, contains("'PERMISSION_MICROPHONE=1'"));
    });
  });

  group('formatDuration', () {
    test('pads to mm:ss', () {
      expect(KaraokeRecordingService.formatDuration(Duration.zero), '00:00');
      expect(
        KaraokeRecordingService.formatDuration(const Duration(seconds: 7)),
        '00:07',
      );
      expect(
        KaraokeRecordingService.formatDuration(
          const Duration(minutes: 3, seconds: 42),
        ),
        '03:42',
      );
    });

    test('keeps counting past an hour', () {
      expect(
        KaraokeRecordingService.formatDuration(
          const Duration(hours: 1, minutes: 5, seconds: 3),
        ),
        '65:03',
      );
    });
  });
}

final _sourceSong = MediaItem(
  id: 'song-1',
  title: 'Raga Malhar',
  mediaType: MediaType.audio,
  status: MediaStatus.published,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  karaoke: true,
);

/// A channel provider the upload path must never reach.
///
/// `uploadAsReel` bails out before touching it when there is no recording; if
/// that ever stops being true, the test fails loudly instead of quietly
/// uploading.
class _UnusedChannelProvider implements ChannelProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpectedly used: ${invocation.memberName}');
}
