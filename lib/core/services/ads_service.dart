import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

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

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Google test banner IDs — safe to use during development
      return defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // ⚠️ TODO: Replace with your real AdMob banner unit IDs before release
    return defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX' // Android live banner
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // iOS live banner
  }

  // ─── Test device IDs ───────────────────────────────────────────────────────
  // Add your physical device's test ID here to see real test ads (not blanks).
  // Find your ID in logcat: look for "Use RequestConfiguration.Builder"
  //   → copy the hex string shown e.g. "33BE2250B43518CCDA7DE426D04EE231"
  // Emulators are already registered automatically — no entry needed.
  static const List<String> _testDeviceIds = [
    // 'YOUR_PHYSICAL_DEVICE_TEST_ID_HERE',  // e.g. '33BE2250B43518CCDA7DE426D04EE231'
  ];

  // ─── Initialisation ────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;

    // Register test devices in debug mode so ads load without policy violation
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }

    await MobileAds.instance.initialize();
  }
}
