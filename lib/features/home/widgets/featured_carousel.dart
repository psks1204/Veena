import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/google_banner_ad.dart';
import '../../../shared/widgets/subscription_modal.dart';

class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({
    super.key,
    required this.items,
    required this.onPlay,
  });

  final List<MediaItem> items;
  final Function(List<MediaItem>, int) onPlay;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _pageCount == 0) return;

      int nextPage = _currentPage + 1;
      if (nextPage >= _pageCount) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    // Restart timer on manual swipe to prevent immediate auto-scroll
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final subscription = context.watch<SubscriptionProvider>();
    final shouldInsertAds =
        subscription.shouldShowAds && AdsService.isSupportedPlatform;
    final pages = _buildPages(widget.items, shouldInsertAds);
    _pageCount = pages.length;

    if (_currentPage >= _pageCount && _pageCount > 0) {
      _currentPage = 0;
    }

    return Column(
      children: [
        SizedBox(
          child: kIsWeb
              ? SizedBox(
                  height: 250, // Halved from 350
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      if (page.isAd) {
                        return _buildAdPage(context, theme);
                      }
                      return _buildFeaturedItem(
                        context,
                        page.item!,
                        theme,
                        page.mediaIndex!,
                      );
                    },
                  ),
                )
              : SizedBox(
                  height: 200, // Halved from 300
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      if (page.isAd) {
                        return _buildAdPage(context, theme);
                      }
                      return _buildFeaturedItem(
                        context,
                        page.item!,
                        theme,
                        page.mediaIndex!,
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Page Indicators
        if (pages.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (theme.brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildFeaturedItem(
    BuildContext context,
    MediaItem item,
    ThemeData theme,
    int mediaIndex,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: (item.hlsUrl != null && item.hlsUrl!.isNotEmpty)
              ? () => widget.onPlay(widget.items, mediaIndex)
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ambient blurred background matching the image color
              if (item.featuredImageUrl != null) ...[
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      item.featuredImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                  ),
                ),
              ] else ...[
                // Fallback Background color
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],

              // Hero Image
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  item.featuredImageUrl ?? '',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[900]),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.artistName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (item.hlsUrl != null && item.hlsUrl!.isNotEmpty)
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onPlay(
                            widget.items,
                            widget.items.indexOf(item),
                          ),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Play Now',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CarouselPage> _buildPages(List<MediaItem> items, bool withAds) {
    if (!withAds) {
      return List.generate(
        items.length,
        (index) => _CarouselPage(item: items[index], mediaIndex: index),
      );
    }

    final pages = <_CarouselPage>[];
    for (int i = 0; i < items.length; i++) {
      pages.add(_CarouselPage(item: items[i], mediaIndex: i));
      pages.add(const _CarouselPage(isAd: true));
    }
    return pages;
  }

  Widget _buildAdPage(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.22),
            Colors.black.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GoogleBannerAd(height: 50),
          const SizedBox(height: 10),
          Text(
            'Remove ads with No Ads plan (Rs 9/month)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => showSubscriptionModal(context),
            child: const Text('Go ad-free'),
          ),
        ],
      ),
    );
  }
}

class _CarouselPage {
  const _CarouselPage({this.item, this.mediaIndex, this.isAd = false});

  final MediaItem? item;
  final int? mediaIndex;
  final bool isAd;
}
