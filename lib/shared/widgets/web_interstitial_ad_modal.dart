import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/brand_ad.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/brand_ads_service.dart';
import '../../core/theme/app_colors.dart';
import 'app_network_image.dart';
import 'subscription_modal.dart';

/// Full-screen/modal Google-style interstitial ad for Web playback gating.
class WebInterstitialAdModal extends StatefulWidget {
  const WebInterstitialAdModal({
    super.key,
    required this.ad,
  });

  final BrandAd ad;

  /// Display the full-screen interstitial ad dialog on Web.
  /// Returns a Future that completes when the ad is closed/skipped.
  static Future<void> show([BuildContext? context]) async {
    if (!kIsWeb) return;

    final targetContext =
        context ?? AppNavigation.rootNavigatorKey.currentContext;
    if (targetContext == null) return;

    final subscription = targetContext.read<SubscriptionProvider>();
    if (subscription.isNoAdsSubscribed || !subscription.shouldShowAds) {
      debugPrint('[WebInterstitialAdModal] User is subscribed, skipping ad');
      return;
    }

    final ad = BrandAdsService.getRandomAd();

    await showDialog<void>(
      context: targetContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => WebInterstitialAdModal(ad: ad),
    );
  }

  @override
  State<WebInterstitialAdModal> createState() => _WebInterstitialAdModalState();
}

class _WebInterstitialAdModalState extends State<WebInterstitialAdModal> {
  int _countdown = 5;
  Timer? _timer;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 0;
          _canSkip = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ad = widget.ad;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
            maxHeight: 620,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF202020)
                        : const Color(0xFFF5F5F5),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00754A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00754A).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ad · Sponsored',
                              style: TextStyle(
                                color: Color(0xFF008952),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Google Ads Partner',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),

                      // Skip / Close Button with Countdown
                      if (_canSkip)
                        ElevatedButton.icon(
                          onPressed: _dismiss,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'Skip Ad',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  value: (5 - _countdown) / 5.0,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Skip in $_countdown s',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Main Interstitial Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Showcase Hero Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Container(
                                height: 220,
                                width: double.infinity,
                                color: Colors.black26,
                                child: AppNetworkImage(
                                  imageUrl: ad.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: isDark
                                        ? Colors.grey[900]
                                        : Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  errorChild: Container(
                                    color: ad.brandColor.withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 64,
                                        color: ad.brandColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Gradient overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Brand Pill
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: Color(0xFF4285F4),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ad.brandName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title & Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.productName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ad.headline,
                                    style: TextStyle(
                                      color: ad.brandColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Color(0xFFFFB800),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ad.rating}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${ad.reviewsCount})',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Description
                        Text(
                          ad.description,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.lightTextSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Offer Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ad.brandColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ad.brandColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer_rounded,
                                size: 14,
                                color: ad.brandColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ad.priceOrOffer,
                                style: TextStyle(
                                  color: ad.brandColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF9F9F9),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // "Remove Ads" button
                      TextButton.icon(
                        onPressed: () {
                          _dismiss();
                          showSubscriptionModal(context);
                        },
                        icon: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Go Ad-Free',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Primary Visit Brand Website Button
                      ElevatedButton.icon(
                        onPressed: () {
                          BrandAdsService.launchAdWebsite(ad.websiteUrl);
                          _dismiss();
                        },
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          ad.callToAction,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ad.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
