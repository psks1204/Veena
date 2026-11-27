import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veena/shared/widgets/nitshop_banner_ad.dart';

/// The web carousel is 250px tall and the banner sits inside the same side
/// margins as the other ads; it must fit at every width without overflowing.
Future<void> _pumpBanner(
  WidgetTester tester, {
  required double width,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: const Scaffold(
        body: Center(child: SizedBox(height: 250, child: NitShopBannerAd())),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      testWidgets('desktop: copy and the store illustration, no overflow', (
        tester,
      ) async {
        await _pumpBanner(tester, width: 1100, brightness: brightness);
        expect(tester.takeException(), isNull);
        expect(find.text('Start free for 7 days'), findsOneWidget);
        expect(find.text('Plans from ₹2,999/month'), findsOneWidget);
        expect(find.text('yourbrand.nitshop.in'), findsOneWidget);
        expect(find.text('GST invoice ready'), findsOneWidget);
      });

      testWidgets('tablet: copy only, no overflow', (tester) async {
        await _pumpBanner(tester, width: 640, brightness: brightness);
        expect(tester.takeException(), isNull);
        expect(find.text('Start free for 7 days'), findsOneWidget);
        expect(find.text('yourbrand.nitshop.in'), findsNothing);
      });

      testWidgets('phone: compact copy, no overflow', (tester) async {
        await _pumpBanner(tester, width: 360, brightness: brightness);
        expect(tester.takeException(), isNull);
        expect(find.text('Start free for 7 days'), findsOneWidget);
        expect(find.text('Plans from ₹2,999/month'), findsNothing);
      });
    });
  }

  test('links go to nitshop.in, tagged as coming from Veena', () {
    expect(NitShopBannerAd.signupUrl, startsWith('https://nitshop.in/signup?'));
    expect(NitShopBannerAd.siteUrl, startsWith('https://nitshop.in/?'));
    for (final url in [NitShopBannerAd.signupUrl, NitShopBannerAd.siteUrl]) {
      expect(Uri.parse(url).queryParameters['utm_source'], 'veena');
    }
  });
}
