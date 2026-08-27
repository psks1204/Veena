import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/brand_ad.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/brand_ads_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_network_image.dart';
import 'subscription_modal.dart';

/// Google Ads styled real-brand sponsored card for Web Carousel and in-feed views.
class WebBrandAdCard extends StatelessWidget {
  const WebBrandAdCard({
    super.key,
    required this.ad,
    this.compact = false,
    this.onAdClosed,
  });

  final BrandAd ad;
  final bool compact;
  final VoidCallback? onAdClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subscription = context.watch<SubscriptionProvider>();

    if (subscription.isNoAdsSubscribed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF181818) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ad.brandColor.withValues(alpha: isDark ? 0.15 : 0.06),
                    isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Left: Product Visual Image with Brand Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: compact ? 120 : 180,
                    height: double.infinity,
                    color: Colors.black12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          imageUrl: ad.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
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
                              Icons.storefront_rounded,
                              size: 40,
                              color: ad.brandColor,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 11,
                                  color: Color(0xFF4285F4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ad.brandName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
                ),

                const SizedBox(width: 16),

                // Right: Ad Copy & Actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top Row: Ad Tag & AdChoices
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00754A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00754A).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Ad · Sponsored',
                              style: TextStyle(
                                color: Color(0xFF008952),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ad.category,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          // Google AdChoices Info Icon
                          Tooltip(
                            message: 'Google Ads Partner · AdChoices',
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Product Title
                      Text(
                        ad.productName,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Headline / Slogan
                      Text(
                        ad.headline,
                        style: TextStyle(
                          color: ad.brandColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.description,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                            fontSize: 12,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Pricing & Rating Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ad.priceOrOffer,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${ad.rating}',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${ad.reviewsCount})',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // CTA Buttons Row
                      Row(
                        children: [
                          // Primary Outbound Button
                          ElevatedButton.icon(
                            onPressed: () =>
                                BrandAdsService.launchAdWebsite(ad.websiteUrl),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: Text(
                              ad.callToAction,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ad.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Secondary "Go Ad-Free" Button
                          TextButton(
                            onPressed: () => showSubscriptionModal(context),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white60
                                  : AppColors.lightTextSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: const Text(
                              'Hide Ads',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
