import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veena/core/models/media_item.dart';
import 'package:veena/shared/utils/share_media.dart';
import 'package:veena/shared/widgets/share_song_button.dart';

/// Regression tests for the share button doing nothing when tapped.
///
/// Two separate faults produced the same symptom: share_plus throws whenever
/// the platform has no share sheet (every desktop browser, and any iPad call
/// without an anchor rect) and nothing caught it, and two controls in
/// full_player were wired to no handler at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> shareCalls;
  late List<MethodCall> clipboardCalls;

  /// Stand in for the platform share sheet. Throws when [fails] is set, the
  /// way share_plus does on a platform with no share sheet.
  void stubShare({bool fails = false}) {
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      if (fails) throw PlatformException(code: 'unavailable');
      return 'dev.fluttercommunity.plus/share/success';
    });
  }

  setUp(() {
    shareCalls = [];
    clipboardCalls = [];

    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
      return null;
    });
    stubShare();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(shareChannel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  MediaItem song({String id = 'abc123', String title = 'Raga Malhar'}) {
    return MediaItem(
      id: id,
      title: title,
      mediaType: MediaType.audio,
      status: MediaStatus.published,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  /// Pump a share button and tap it.
  Future<void> tapShare(WidgetTester tester, MediaItem media) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: ShareSongButton(media: media))),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
  }

  group('share link', () {
    test('points at the song deep link', () {
      expect(mediaShareUrl('abc123'),
          'https://veenamusiconline.com/song/abc123');
    });
  });

  group('ShareSongButton', () {
    testWidgets('a tap reaches the platform share sheet', (tester) async {
      await tapShare(tester, song());

      expect(shareCalls, hasLength(1));
      expect(shareCalls.single.method, 'share');

      final args = shareCalls.single.arguments as Map;
      expect(args['text'], contains('Raga Malhar'));
      expect(args['text'],
          contains('https://veenamusiconline.com/song/abc123'));
    });

    testWidgets('passes an anchor rect so the iPad popover can attach',
        (tester) async {
      await tapShare(tester, song());

      final args = shareCalls.single.arguments as Map;
      // A zero-area origin is what leaves the iPad sheet with nowhere to go.
      expect(args['originWidth'], greaterThan(0));
      expect(args['originHeight'], greaterThan(0));
    });

    testWidgets('falls back to the clipboard when no share sheet exists',
        (tester) async {
      stubShare(fails: true);
      await tapShare(tester, song());

      expect(shareCalls, hasLength(1), reason: 'it still tries the sheet');
      expect(clipboardCalls, hasLength(1),
          reason: 'the link should land on the clipboard instead');

      final copied =
          (clipboardCalls.single.arguments as Map)['text'] as String;
      expect(copied, contains('https://veenamusiconline.com/song/abc123'));
    });

    testWidgets('tells the user when the share sheet is unavailable',
        (tester) async {
      stubShare(fails: true);
      await tapShare(tester, song());

      // The bug was a tap with no visible outcome whatsoever.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('link copied'), findsOneWidget);
    });

    testWidgets('a failing share does not throw out of the tap',
        (tester) async {
      stubShare(fails: true);
      await tapShare(tester, song());

      expect(tester.takeException(), isNull);
    });
  });

  group('shareMediaLink', () {
    testWidgets('reports failure when the clipboard is unavailable too',
        (tester) async {
      stubShare(fails: true);
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'unavailable');
        }
        return null;
      });

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (c) {
              ctx = c;
              return const SizedBox();
            }),
          ),
        ),
      );

      await shareMediaLink(ctx, title: 'Raga Malhar', url: 'https://x/y');
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not share'), findsOneWidget);
    });
  });
}
