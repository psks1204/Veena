import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veena/shared/utils/on_screen_playback.dart';

/// Records every playback-allowed change, standing in for a reel feed.
class _Reels extends StatefulWidget {
  const _Reels(this.log);
  final List<bool> log;

  @override
  State<_Reels> createState() => _ReelsState();
}

class _ReelsState extends State<_Reels> with OnScreenPlaybackMixin {
  @override
  void onPlaybackAllowedChanged(bool allowed) => widget.log.add(allowed);

  @override
  Widget build(BuildContext context) => const Text('reels');
}

/// Mirrors AppShell: tabs kept alive in an IndexedStack, each in its own
/// navigator, with tickers off for every tab but the selected one.
class _Shell extends StatelessWidget {
  const _Shell({required this.index, required this.log, this.feedKey});
  final int index;
  final List<bool> log;
  final GlobalKey<NavigatorState>? feedKey;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      Navigator(
        key: feedKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => Scaffold(body: _Reels(log))),
      ),
      const Text('home'),
    ];
    return MaterialApp(
      home: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            TickerMode(enabled: i == index, child: tabs[i]),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('switching tabs stops the feed, coming back resumes it', (
    tester,
  ) async {
    final log = <bool>[];
    await tester.pumpWidget(_Shell(index: 0, log: log));
    expect(log, isEmpty);

    await tester.pumpWidget(_Shell(index: 1, log: log));
    await tester.pump();
    expect(log, [false]);

    await tester.pumpWidget(_Shell(index: 0, log: log));
    await tester.pump();
    expect(log, [false, true]);
  });

  testWidgets('a page opened over the feed stops it until closed', (
    tester,
  ) async {
    final log = <bool>[];
    final feed = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_Shell(index: 0, log: log, feedKey: feed));

    feed.currentState!.push(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('channel'))),
    );
    await tester.pumpAndSettle();
    expect(log, [false]);

    feed.currentState!.pop();
    await tester.pumpAndSettle();
    expect(log, [false, true]);
  });

  testWidgets('backgrounding the app stops the feed', (tester) async {
    final log = <bool>[];
    await tester.pumpWidget(_Shell(index: 0, log: log));

    // Step through the states a device actually reports.
    void go(List<AppLifecycleState> states) {
      for (final s in states) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
    }

    go(const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(log, [false]);

    go(const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    expect(log, [false, true]);
  });
}
