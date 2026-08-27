import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/brand_ad.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/brand_ads_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_network_image.dart';
import 'subscription_modal.dart';

/// Rotating Google-style real brand ad unit for Web Player and Now Playing Panel.
class WebPlayerBrandAd extends StatefulWidget {
  const WebPlayerBrandAd({
    super.key,
    this.compact = false,
    this.showBorder = true,
  });

  final bool compact;
  final bool showBorder;

  @override
  State<WebPlayerBrandAd> createState() => _WebPlayerBrandAdState();
}

class _WebPlayerBrandAdState extends State<WebPlayerBrandAd> {
  BrandAd? _currentAd;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _currentAd = BrandAdsService.getNextAd();
    _startRotationTimer();
  }

  void _startRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      if (!mounted) return;
      setState(() {
        _currentAd = BrandAdsService.getNextAd();
      });
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final subscription = context.watch<SubscriptionProvider>();
    if (subscription.isNoAdsSubscribed || !subscription.shouldShowAds) {
      return const SizedBox.shrink();
    }

    final ad = _currentAd ?? BrandAdsService.brandAds.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(ad.id),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: widget.showBorder
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // Product Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: AppNetworkImage(
                  imageUrl: ad.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.black12,
                    child: const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  errorChild: Container(
                    color: ad.brandColor.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 24,
                      color: ad.brandColor,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Ad Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sponsored Tag & Brand
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00754A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Ad',
                          style: TextStyle(
                            color: Color(0xFF008952),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ad.brandName,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: Color(0xFF4285F4),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Headline
                  Text(
                    ad.headline,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 1),

                  // Offer & Rating
                  Row(
                    children: [
                      Text(
                        ad.priceOrOffer,
                        style: TextStyle(
                          color: ad.brandColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Color(0xFFFFB800),
                      ),
                      Text(
                        '${ad.rating}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Outbound Action
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      BrandAdsService.launchAdWebsite(ad.websiteUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ad.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: const Size(64, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shop',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.open_in_new_rounded, size: 10),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => showSubscriptionModal(context),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Remove ads',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white38 : Colors.black38,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
