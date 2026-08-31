import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veena/core/navigation/app_navigation.dart';

/// Mirrors the real gate screens (DOB / name / channel setup), which block
/// dismissal with PopScope(canPop: false).
class _UndismissableGate extends StatelessWidget {
  const _UndismissableGate();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(body: Center(child: Text('When is your birthday?'))),
    );
  }
}

/// Stands in for _AppRouter: swaps home on auth state, exactly as the real
/// router does when a 401 signs the user out.
class _Router extends StatelessWidget {
  const _Router({required this.authed});
  final bool authed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigation.rootNavigatorKey,
      home: Scaffold(body: Center(child: Text(authed ? 'Home' : 'Login'))),
    );
  }
}

void main() {
  testWidgets(
    'a session ending behind an undismissable gate leaves the user on login',
    (tester) async {
      await tester.pumpWidget(const _Router(authed: true));
      expect(find.text('Home'), findsOneWidget);

      // User is sent to the mandatory DOB gate.
      AppNavigation.rootNavigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const _UndismissableGate()),
      );
      await tester.pumpAndSettle();
      expect(find.text('When is your birthday?'), findsOneWidget);

      // A 401 arrives: the router swaps home to the login screen.
      await tester.pumpWidget(const _Router(authed: false));
      await tester.pumpAndSettle();

      // Regression: without popRootToFirst the gate stays on top of the stack
      // and, being PopScope(canPop: false), traps the user permanently.
      expect(
        find.text('When is your birthday?'),
        findsOneWidget,
        reason: 'gate is still stacked above login until it is popped',
      );

      AppNavigation.popRootToFirst();
      await tester.pumpAndSettle();

      expect(find.text('When is your birthday?'), findsNothing);
      expect(find.text('Login'), findsOneWidget);
    },
  );

  testWidgets('popRootToFirst is a no-op when nothing is stacked', (
    tester,
  ) async {
    await tester.pumpWidget(const _Router(authed: false));
    expect(AppNavigation.popRootToFirst(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
