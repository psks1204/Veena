import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/subscription_provider.dart';
import '../../core/services/ads_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'google_banner_ad.dart';
import 'subscription_modal.dart';

class PlayerAdRotator extends StatefulWidget {
  const PlayerAdRotator({super.key});

  @override
  State<PlayerAdRotator> createState() => _PlayerAdRotatorState();
}

class _PlayerAdRotatorState extends State<PlayerAdRotator>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _showAd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() => _showAd = !_showAd);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    debugPrint('[PlayerAdRotator] isLoading=${subscription.isLoading}, isInitialized=${subscription.isInitialized}, isNoAdsSubscribed=${subscription.isNoAdsSubscribed}, shouldShowAds=${subscription.shouldShowAds}, isSupportedPlatform=${AdsService.isSupportedPlatform}');
    if (subscription.isLoading && !subscription.isInitialized) {
      debugPrint('[PlayerAdRotator] Still loading subscription, hiding ads');
      return const SizedBox.shrink();
    }

    if (subscription.isNoAdsSubscribed) {
      debugPrint('[PlayerAdRotator] User is subscribed (no-ads), hiding ads');
      return const SizedBox.shrink();
    }

    final showAds =
        subscription.shouldShowAds && AdsService.hasAdSurface;

    if (!showAds) {
      return _promoBanner(context, subscription.monthlyPlanLabel);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _showAd
          ? const GoogleBannerAd(key: ValueKey('player_ad'))
          : _promoBanner(
              context,
              subscription.monthlyPlanLabel,
              key: const ValueKey('player_promo'),
            ),
    );
  }

  Widget _promoBanner(BuildContext context, String plan, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Go ad-free for $plan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => showSubscriptionModal(context),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
