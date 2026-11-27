import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veena/core/navigation/app_navigation.dart';
import 'package:veena/core/navigation/app_tabs.dart';
import 'package:veena/shared/layouts/shop_shell.dart';

/// A tab navigator showing [label], keyed like the real shells key theirs.
Widget _tab(GlobalKey<NavigatorState> key, String label) => Navigator(
  key: key,
  onGenerateRoute: (settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => Scaffold(body: Center(child: Text(label))),
  ),
);

void main() {
  const musicTabs = [
    AppTabs.home,
    AppTabs.uploads,
    AppTabs.search,
    AppTabs.karaoke,
    AppTabs.library,
    AppTabs.profile,
  ];

  test('shop tabs get their own navigator keys, none shared with music', () {
    final shopKeys = [for (var i = 0; i < 4; i++) ShopShell.navigatorKeyFor(i)];
    expect(shopKeys, [
      AppNavigation.shopHomeKey,
      AppNavigation.shopOrdersKey,
      AppNavigation.shopWishlistKey,
      AppNavigation.shopCartKey,
    ]);
    for (final tab in musicTabs) {
      expect(
        shopKeys,
        isNot(contains(AppNavigation.getNavigatorKey(tab))),
        reason: 'shop would share music tab $tab\'s navigator',
      );
    }
  });

  testWidgets('opening the shop after Profile shows the store, not Profile', (
    tester,
  ) async {
    // The music shell with the Profile tab visited…
    await tester.pumpWidget(
      MaterialApp(
        home: _tab(AppNavigation.getNavigatorKey(AppTabs.profile), 'Profile'),
      ),
    );
    expect(find.text('Profile'), findsOneWidget);

    // …swapped for the shop shell in one frame, as tapping Shop does.
    // Regression: with a shared key Flutter moved the Profile navigator into
    // the Store tab, so this showed "Profile".
    await tester.pumpWidget(
      MaterialApp(home: _tab(ShopShell.navigatorKeyFor(0), 'Store')),
    );
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });
}
