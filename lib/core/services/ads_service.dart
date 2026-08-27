import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../shared/widgets/web_interstitial_ad_modal.dart';

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
  /// Platforms where the AdMob (google_mobile_ads) SDK actually runs.
  /// Web is deliberately excluded — there ads come from real brand Google ads / AdSense.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Web serves ads through custom Google-styled brand ads / AdSense.
  static bool get isAdSenseSupported => kIsWeb;

  /// Whether *any* ad surface exists on this platform. UI gating should use
  /// this; only AdMob-specific calls should use [isSupportedPlatform].
  static bool get hasAdSurface => isSupportedPlatform || kIsWeb;

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

  // ─── Global ads gate ───────────────────────────────────────────────────────
  // Single source of truth for "may this app show ads at all". A no-ads
  // subscriber must never see a banner *or* an interstitial, so every ad entry
  // point goes through this flag instead of each caller re-deriving it.
  // Kept in sync by SubscriptionProvider.
  static bool _adsEnabled = true;
  static bool _mobileAdsInitialized = false;

  static bool get adsEnabled => _adsEnabled;

  /// True when an ad may actually be requested/shown right now, on whichever
  /// ad network this platform uses.
  static bool get canShowAds => _adsEnabled && hasAdSurface;

  /// True when an AdMob (mobile) ad may be requested. Web ad surfaces must not
  /// use this — google_mobile_ads has no web implementation.
  static bool get canShowAdMobAds => _adsEnabled && isSupportedPlatform;

  /// Turn ads on/off globally. Disabling drops any preloaded interstitial so a
  /// user who subscribes mid-session never gets the already-cached ad.
  static void setAdsEnabled(bool value) {
    if (_adsEnabled == value) return;
    _adsEnabled = value;

    if (!value) {
      debugPrint('[AdsService] Ads disabled — discarding preloaded ads');
      _disposeInterstitialAd();
      return;
    }

    debugPrint('[AdsService] Ads enabled');
    if (_mobileAdsInitialized) {
      loadInterstitialAd();
    }
  }

  // ─── Interstitial ad state ─────────────────────────────────────────────────
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  // ─── Initialisation ────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;

    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }

    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;

    // Preload the first interstitial ad
    loadInterstitialAd();
  }

  // ─── Interstitial ad methods ───────────────────────────────────────────────

  /// Preload an interstitial ad so it's ready when needed.
  static void loadInterstitialAd() {
    // Interstitials are AdMob-only; there is no web equivalent here.
    if (!_adsEnabled || !isSupportedPlatform) return;

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
    if (!_adsEnabled) {
      // No-ads subscriber (or ads switched off) — never show, never preload.
      _disposeInterstitialAd();
      return;
    }

    // Web platform interstitial modal
    if (kIsWeb) {
      await WebInterstitialAdModal.show();
      return;
    }

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
