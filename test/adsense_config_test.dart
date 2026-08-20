import 'package:flutter_test/flutter_test.dart';
import 'package:veena/core/services/adsense_config.dart';

void main() {
  const goodClient = 'ca-pub-1875243491329741';

  group('AdSenseConfig.validateClient', () {
    test('accepts a ca-pub- publisher id', () {
      expect(AdSenseConfig.validateClient(goodClient), isNull);
    });

    test('rejects a publisher id missing the ca- prefix', () {
      expect(
        AdSenseConfig.validateClient('pub-8580707712580721'),
        contains('ADSENSE_CLIENT'),
      );
    });
  });

  group('AdSenseConfig.validateSlot', () {
    test('accepts a numeric slot id', () {
      expect(AdSenseConfig.validateSlot('3611087263', 'SLOT'), isNull);
    });

    test('accepts an unset slot — that placement simply stays hidden', () {
      expect(AdSenseConfig.validateSlot('', 'SLOT'), isNull);
    });

    test('catches the publisher id being pasted into a slot field', () {
      expect(
        AdSenseConfig.validateSlot('ca-pub-8580707712580721', 'SLOT'),
        contains('numeric data-ad-slot'),
      );
    });

    test('catches an ad unit name pasted instead of the slot id', () {
      expect(
        AdSenseConfig.validateSlot('Veena Display', 'SLOT'),
        contains('digits only'),
      );
    });
  });

  group('AdSenseConfig defaults', () {
    test('ships both ad units and a valid publisher id', () {
      expect(AdSenseConfig.client, startsWith('ca-pub-'));
      expect(AdSenseConfig.displaySlot, '3611087263');
      expect(AdSenseConfig.inFeedSlot, '3354956458');
      expect(AdSenseConfig.inFeedLayoutKey, isNotEmpty);
      expect(AdSenseConfig.configError, isNull);
      expect(AdSenseConfig.isConfigured, isTrue);
    });

    test('maps each placement format to its own unit', () {
      expect(
        AdSenseConfig.slotFor(AdSenseFormat.display),
        AdSenseConfig.displaySlot,
      );
      expect(
        AdSenseConfig.slotFor(AdSenseFormat.inFeed),
        AdSenseConfig.inFeedSlot,
      );
      expect(
        AdSenseConfig.slotFor(AdSenseFormat.display),
        isNot(AdSenseConfig.slotFor(AdSenseFormat.inFeed)),
      );
    });
  });
}
