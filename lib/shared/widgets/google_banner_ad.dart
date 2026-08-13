import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ads_service.dart';
import '../../core/services/adsense_config.dart';
import 'adsense_ad_unit.dart';

class GoogleBannerAd extends StatefulWidget {
  const GoogleBannerAd({
    super.key,
    this.height = 50,
    this.enabled = true,
    this.margin,
    this.webFormat = AdSenseFormat.display,
    this.webMaxHeight,
  });

  final double height;
  final bool enabled;
  final EdgeInsetsGeometry? margin;

  /// Which AdSense unit this placement requests on web. Ignored on mobile,
  /// where every placement is the same AdMob banner.
  final AdSenseFormat webFormat;

  /// Ceiling for a web in-feed unit that comes back taller than [height].
  final double? webMaxHeight;

  @override
  State<GoogleBannerAd> createState() => _GoogleBannerAdState();
}

class _GoogleBannerAdState extends State<GoogleBannerAd> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _loading = false;
  String? _lastError;
  int _retryCount = 0;

  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant GoogleBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (!widget.enabled) {
        _disposeBanner();
      } else {
        _loadBannerIfNeeded();
      }
    }
  }

  Future<void> _loadBannerIfNeeded() async {
    // AdMob only. On web this widget delegates to AdSense in build(), so the
    // log would just be noise next to the [AdSense] lines.
    if (kIsWeb) return;

    debugPrint('[GoogleBannerAd] _loadBannerIfNeeded called: enabled=${widget.enabled}, supported=${AdsService.isSupportedPlatform}, bannerAd=${_bannerAd != null}, loading=$_loading');
    if (!widget.enabled || !AdsService.canShowAdMobAds) return;
    if (_bannerAd != null) return;
    if (_loading) return;

    final width = MediaQuery.sizeOf(context).width.floor();
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    final adSize = adaptiveSize ?? AdSize.banner;

    setState(() {
      _loading = true;
      _lastError = null;
    });

    debugPrint('[GoogleBannerAd] Loading banner ad with unitId: ${AdsService.bannerAdUnitId}, size: $adSize');
    final ad = BannerAd(
      adUnitId: AdsService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[GoogleBannerAd] ✅ Banner ad loaded successfully!');
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
            _loading = false;
            _lastError = null;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[GoogleBannerAd] ❌ Banner ad failed to load: ${error.message} (code: ${error.code})');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _loaded = false;
            _loading = false;
            _lastError = error.message;
          });

          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(const Duration(milliseconds: 900), () {
              if (!mounted) return;
              _loadBannerIfNeeded();
            });
          }
        },
      ),
    );

    ad.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loaded = false;
    _loading = false;
    _lastError = null;
    _retryCount = 0;
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !AdsService.canShowAds) {
      return const SizedBox.shrink();
    }

    // Web has no AdMob SDK — the same placement is served by AdSense.
    if (kIsWeb) {
      return AdSenseAdUnit(
        height: widget.height,
        maxHeight: widget.webMaxHeight,
        margin: widget.margin,
        format: widget.webFormat,
      );
    }

    if (!_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
