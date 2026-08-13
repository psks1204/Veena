import 'package:flutter/foundation.dart';

/// Which AdSense unit a placement should request.
enum AdSenseFormat {
  /// Display unit, rendered at the size Flutter reserved for it. Used for the
  /// banner strips (player rotator, artwork swap).
  display,

  /// In-feed ("fluid") unit, which sizes its own height. Used for the ad card
  /// inside the featured carousel, which is a feed of cards.
  inFeed,
}

/// AdSense configuration for the web build.
///
/// The loader script in `web/index.html` only pulls in Google's library — it
/// does not create ads by itself. An ad appears only when an
/// `<ins class="adsbygoogle">` element carrying a **publisher id + slot id**
/// exists in the DOM and gets pushed to the `adsbygoogle` queue. Auto ads are
/// not an option for us: they scan the page's HTML for places to inject, and a
/// Flutter web app renders into a canvas with essentially no HTML to scan.
///
/// Values come from `env/web.json` (see `--dart-define-from-file` in the build
/// command), so nothing here has to be edited to ship a new slot:
///
/// ```
/// flutter build web --release --dart-define-from-file=env/web.json
/// ```
class AdSenseConfig {
  const AdSenseConfig._();

  static const String _rawClient = String.fromEnvironment(
    'ADSENSE_CLIENT',
    defaultValue: 'ca-pub-8580707712580721',
  );

  static const String _rawDisplaySlot = String.fromEnvironment(
    'ADSENSE_SLOT_DISPLAY',
    defaultValue: '3611087263',
  );

  static const String _rawInFeedSlot = String.fromEnvironment(
    'ADSENSE_SLOT_INFEED',
    defaultValue: '3354956458',
  );

  static const String _rawInFeedLayoutKey = String.fromEnvironment(
    'ADSENSE_INFEED_LAYOUT_KEY',
    defaultValue: '-6t+ed+2i-1n-4w',
  );

  /// Publisher id. Must match the `client=` parameter of the loader script in
  /// `web/index.html`, otherwise AdSense silently refuses to fill the slot.
  static String get client => _rawClient.trim();

  /// `data-ad-slot` of the Display ad unit.
  static String get displaySlot => _rawDisplaySlot.trim();

  /// `data-ad-slot` of the In-feed ad unit.
  static String get inFeedSlot => _rawInFeedSlot.trim();

  /// `data-ad-layout-key` that pairs with [inFeedSlot]. In-feed units will not
  /// render without the layout key generated alongside them in AdSense.
  static String get inFeedLayoutKey => _rawInFeedLayoutKey.trim();

  static String slotFor(AdSenseFormat format) => switch (format) {
    AdSenseFormat.display => displaySlot,
    AdSenseFormat.inFeed => inFeedSlot,
  };

  /// Ads can only render once we know which unit to request.
  static bool get isConfigured =>
      client.isNotEmpty && displaySlot.isNotEmpty && configError == null;

  /// Human-readable reason the configuration cannot work, or null when it is
  /// usable. Surfaced once at startup so a mistyped id fails loudly in the
  /// console instead of silently serving nothing.
  static String? get configError {
    final clientError = validateClient(client);
    if (clientError != null) return clientError;

    final displayError = validateSlot(displaySlot, 'ADSENSE_SLOT_DISPLAY');
    if (displayError != null) return displayError;

    final inFeedError = validateSlot(inFeedSlot, 'ADSENSE_SLOT_INFEED');
    if (inFeedError != null) return inFeedError;

    if (inFeedSlot.isNotEmpty && inFeedLayoutKey.isEmpty) {
      return 'ADSENSE_SLOT_INFEED is set but ADSENSE_INFEED_LAYOUT_KEY is '
          'empty — an in-feed unit does not render without its layout key.';
    }
    return null;
  }

  @visibleForTesting
  static String? validateClient(String client) {
    if (client.isNotEmpty && !client.startsWith('ca-pub-')) {
      return 'ADSENSE_CLIENT should look like "ca-pub-0000000000000000", got "$client".';
    }
    return null;
  }

  /// Pure form of the slot rules so they can be exercised in tests without a
  /// build-time define.
  @visibleForTesting
  static String? validateSlot(String slot, String name) {
    if (slot.isEmpty) return null;
    if (slot.startsWith('ca-')) {
      return '$name is the numeric data-ad-slot value, not a publisher/ad-unit '
          'path — got "$slot".';
    }
    if (!RegExp(r'^\d+$').hasMatch(slot)) {
      return '$name must be digits only, got "$slot".';
    }
    return null;
  }

  static bool _warned = false;

  /// Logs a one-time explanation when web ads cannot run. Called from the ad
  /// widget so the reason shows up exactly where someone would look for it.
  static void warnIfMisconfigured() {
    if (_warned || !kIsWeb) return;
    _warned = true;

    final error = configError;
    if (error != null) {
      debugPrint('[AdSense] configuration ignored — $error');
      return;
    }
    if (displaySlot.isEmpty) {
      debugPrint(
        '[AdSense] no ad unit configured: set ADSENSE_SLOT_DISPLAY in '
        'env/web.json to the data-ad-slot of a Display unit. Web ads stay '
        'hidden until then.',
      );
    }
  }
}
