import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/subscription_provider.dart';
import '../../core/services/ads_service.dart';
import '../../core/theme/app_colors.dart';
import 'google_banner_ad.dart';

class PlayerArtworkAdSwap extends StatefulWidget {
  const PlayerArtworkAdSwap({super.key, this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  State<PlayerArtworkAdSwap> createState() => _PlayerArtworkAdSwapState();
}

class _PlayerArtworkAdSwapState extends State<PlayerArtworkAdSwap> {
  Timer? _timer;
  bool _showAd = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _showAd = !_showAd);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final shouldRotate =
        subscription.shouldShowAds && AdsService.isSupportedPlatform;

    final showAdNow = shouldRotate && _showAd;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: showAdNow
          ? _AdView(key: const ValueKey('artwork_ad'))
          : _ArtworkView(
              key: const ValueKey('artwork_image'),
              thumbnailUrl: widget.thumbnailUrl,
            ),
    );
  }
}

class _AdView extends StatelessWidget {
  const _AdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          GoogleBannerAd(height: 50),
          SizedBox(height: 10),
          Text(
            'Ad breaks every 5s',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkView extends StatelessWidget {
  const _ArtworkView({super.key, required this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(thumbnailUrl!, fit: BoxFit.cover);
    }

    return Container(
      color: Colors.grey[900],
      child: const Icon(
        Icons.music_note_rounded,
        size: 80,
        color: Colors.white24,
      ),
    );
  }
}
