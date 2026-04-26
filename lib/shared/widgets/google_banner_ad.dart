import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ads_service.dart';

class GoogleBannerAd extends StatefulWidget {
  const GoogleBannerAd({
    super.key,
    this.height = 50,
    this.enabled = true,
    this.margin,
  });

  final double height;
  final bool enabled;
  final EdgeInsetsGeometry? margin;

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
    if (!widget.enabled || !AdsService.isSupportedPlatform) return;
    if (_bannerAd != null) return;
    if (_loading) return;

    final width = MediaQuery.sizeOf(context).width.floor();
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    final adSize = adaptiveSize ?? AdSize.banner;

    setState(() {
      _loading = true;
      _lastError = null;
    });

    final ad = BannerAd(
      adUnitId: AdsService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
            _loading = false;
            _lastError = null;
          });
        },
        onAdFailedToLoad: (ad, error) {
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
    if (!widget.enabled || !AdsService.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    if (!_loaded || _bannerAd == null) {
      return Container(
        margin: widget.margin,
        height: _loading ? widget.height : (widget.height + 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _loading
              ? 'Loading ad...'
              : (_lastError == null
                    ? 'Ad unavailable right now'
                    : 'Ad unavailable: $_lastError'),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      margin: widget.margin,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
