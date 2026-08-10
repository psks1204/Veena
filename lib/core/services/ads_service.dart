import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  // Google's official test interstitial IDs
  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  // ─── Platform guard ────────────────────────────────────────────────────────
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // ─── Ad unit IDs ───────────────────────────────────────────────────────────
  // In debug mode we always use Google's official test IDs so no real traffic
  // is generated and your AdMob account stays healthy.
  // In release mode, swap in your real unit IDs from the AdMob dashboard.

  // Live Android banner ad unit ID from AdMob.
  static const String _androidLiveBannerAdUnitId =
      'ca-app-pub-1875243491329741/5605835413';

  // iOS is currently configured with the same banner unit ID.
  // If you create a dedicated iOS ad unit in AdMob, replace this value only.
  static const String _iosLiveBannerAdUnitId =
      'ca-app-pub-1875243491329741/9428550412';

  // Live interstitial ad unit IDs
  static const String _androidLiveInterstitialAdUnitId =
      'ca-app-pub-1875243491329741/2816588767';
  static const String _iosLiveInterstitialAdUnitId =
      'ca-app-pub-1875243491329741/3162524962';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? _androidTestBannerAdUnitId
          : _iosTestBannerAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidLiveBannerAdUnitId
        : _iosLiveBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.android
          ? _androidTestInterstitialAdUnitId
          : _iosTestInterstitialAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidLiveInterstitialAdUnitId
        : _iosLiveInterstitialAdUnitId;
  }

  // ─── Test device IDs ───────────────────────────────────────────────────────
  static const List<String> _testDeviceIds = [];

  // ─── Interstitial ad state ─────────────────────────────────────────────────
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  // ─── Initialisation ────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;

    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }

    await MobileAds.instance.initialize();

    // Preload the first interstitial ad
    loadInterstitialAd();
  }

  // ─── Interstitial ad methods ───────────────────────────────────────────────

  /// Preload an interstitial ad so it's ready when needed.
  static void loadInterstitialAd() {
    if (!isSupportedPlatform) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdsService] Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdsService] Interstitial ad failed to load: ${error.message}',
          );
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Show the interstitial ad. Returns a Future that completes when
  /// the ad is dismissed (or immediately if no ad is ready).
  /// Only shows if the app is in the foreground.
  static Future<void> showInterstitialAd() async {
    if (!isSupportedPlatform || !_isInterstitialAdReady || _interstitialAd == null) {
      // No ad ready — don't block playback
      loadInterstitialAd(); // Try to load for next time
      return;
    }

    // Only show ads when the app is in the foreground
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != AppLifecycleState.resumed) {
      debugPrint('[AdsService] App not in foreground, skipping interstitial ad');
      return;
    }

    final completer = Completer<void>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdsService] Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
        loadInterstitialAd(); // Preload next ad
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdsService] Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
        loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await _interstitialAd!.show();
    return completer.future;
  }
}
