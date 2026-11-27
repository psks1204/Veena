import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veena/shared/widgets/animated_indexed_stack.dart';

/// A tab that remembers how often it was tapped, to prove state survives.
class _Counter extends StatefulWidget {
  const _Counter(this.label);
  final String label;
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => taps++),
    child: Text('${widget.label} $taps'),
  );
}

Widget _app(int index, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: AnimatedIndexedStack(
        index: index,
        children: const [_Counter('home'), _Counter('feed')],
      ),
    ),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(AnimatedIndexedStack),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  testWidgets('a newly selected tab fades in, then sits fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);

    await tester.pumpWidget(_app(1));
    // Starts faint, never fully transparent (no empty frame between tabs).
    expect(_opacity(tester), closeTo(0.2, 0.01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester), inExclusiveRange(0.25, 1.0)); // mid-fade
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(find.text('feed 0'), findsOneWidget);
  });

  testWidgets('tabs keep their state across switches', (tester) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('home 0'));
    await tester.pump();
    expect(find.text('home 1'), findsOneWidget);

    await tester.pumpWidget(_app(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(find.text('home 1'), findsOneWidget);
  });

  testWidgets('no animation when the system asks to remove animations', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0, disableAnimations: true));
    expect(_opacity(tester), 1);
    await tester.pumpWidget(_app(1, disableAnimations: true));
    expect(_opacity(tester), 1);
  });
}
