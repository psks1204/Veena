import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/open_url.dart';
import 'app_network_image.dart';
import 'section_header.dart';

class FeaturedYoutubeChannel {
  const FeaturedYoutubeChannel({
    required this.title,
    required this.subscribers,
    required this.handle,
    required this.url,
    required this.avatarUrl,
  });

  final String title;
  final String subscribers;
  final String handle;
  final String url;
  final String avatarUrl;
}

const List<FeaturedYoutubeChannel> featuredYoutubeChannels = [
  FeaturedYoutubeChannel(
    title: 'Chantu Bantu - Kids Animated Stories',
    subscribers: '540 subscribers',
    handle: '@ChantuBantuKids',
    url: 'https://www.youtube.com/@ChantuBantuKids',
    avatarUrl:
        'https://yt3.googleusercontent.com/ohU2ZcQEdQRKSF7eKcPG6skQIvfXpxOlXUFoRrXjJ0VFzTFva_49rTuiMIlp1KPFU39eUXxq=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Nursery Rhymes - Veena Rhymes for Kids',
    subscribers: '9.28K subscribers',
    handle: '@NurseryRhymesChannels',
    url: 'https://www.youtube.com/@NurseryRhymesChannels',
    avatarUrl:
        'https://yt3.googleusercontent.com/k-1bB1xGQrqrfeMTXJH4nukBnpncEIBUWsNsW9JaoPeU3BrmhOZm0OiWSzfaz2cMSHa5m8_WlA=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'VEENA SUPERSTAR HINDI',
    subscribers: '73.2K subscribers',
    handle: '@veenasuperstarhindi7509',
    url: 'https://www.youtube.com/@veenasuperstarhindi7509',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_nCu8sG8H9215gRrIeWNgksgoXk4-rH2vcBcKr9JGzl_A=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Superstar English',
    subscribers: '5.36K subscribers',
    handle: '@veenasuperstarenglish67',
    url: 'https://www.youtube.com/@veenasuperstarenglish67',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_lf3shpjqi4Tn_tlMtwf37NDw8D7P-Y32zRTSbo6I-cmg=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Music Bhakti',
    subscribers: '358K subscribers',
    handle: '@VeenaMusicBhakti',
    url: 'https://www.youtube.com/@VeenaMusicBhakti',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_msbE54DAhCFk2gLNAL4fBmt3Vw0VBtXWc4ywyGXASKrQ=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Music',
    subscribers: '4.93M subscribers',
    handle: '@VeenaMusicRajasthani',
    url: 'https://www.youtube.com/@VeenaMusicRajasthani',
    avatarUrl:
        'https://yt3.googleusercontent.com/q5K14H9tjsaeDVlUMG7GY5Yvfz6GGOIFp6LlY4kQCURPUAuoATmKk_phbDy1nnsu-H8PCDVDlIM=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Surango Rajasthan',
    subscribers: '6.02K subscribers',
    handle: '@surangorajasthani',
    url: 'https://www.youtube.com/@surangorajasthani',
    avatarUrl:
        'https://yt3.googleusercontent.com/FiCmlMbrzEISv1J-AIyYrb4Go2NXaMwgaTbMTU9zMdihjfR4bD_KWX2jeHWLdDAnS6CSDnuhOA=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Bhakti Sarover',
    subscribers: '25K subscribers',
    handle: '@VeenaBhaktiSarover',
    url: 'https://www.youtube.com/@VeenaBhaktiSarover',
    avatarUrl:
        'https://yt3.googleusercontent.com/zHXL0Bd0qhFwPih_XTh2ApDBHqwhHtRXimOxMN-bbPd7l_wRYlKaN2vpI5bEaOalj-cbNpsd=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Gorband',
    subscribers: '36.7K subscribers',
    handle: '@Gorbandnakhralo',
    url: 'https://www.youtube.com/@Gorbandnakhralo',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_mDGQf_5UDG1lWXqW5B55SsLo7pVHAmUyBlmlKVKP2v9w=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Superstar Punjabi',
    subscribers: '7.38K subscribers',
    handle: '@veenasuperstarpunjabi',
    url: 'https://www.youtube.com/@veenasuperstarpunjabi',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_nUHnpaIXxQ0Zp42GXy1EdM_TAECyxNM7G2mRwtIyIv7w=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Superstar Bhojpuri',
    subscribers: '2.69K subscribers',
    handle: '@veenasuperstarbhojpuri',
    url: 'https://www.youtube.com/@veenasuperstarbhojpuri',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_lnjJSHxsLzIlbOlX0rY3DLPtUXXkxytOheD7aB5nsESw=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Superstar Bangla',
    subscribers: '71.1K subscribers',
    handle: '@veenasuperstarbangla',
    url: 'https://www.youtube.com/@veenasuperstarbangla',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_kd58dJcnQIaRVmHi3JZvz9fuqKnuJR5jn_bgLG55wmGg=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'VEENA SUPERSTAR GUJARATI',
    subscribers: '85.8K subscribers',
    handle: '@veenasuperstargujarati6303',
    url: 'https://www.youtube.com/@veenasuperstargujarati6303',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_mRepl0ZbqSnnMEnT-nPR0XQMYyuBT8z7cX-hmwL7PSUw=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Superstar Rajasthani',
    subscribers: '7.21K subscribers',
    handle: '@veenasuperstarrajasthani1121',
    url: 'https://www.youtube.com/@veenasuperstarrajasthani1121',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_lOgX5UUV6_Nbh9llD7ceC1Ked8SM8E2fBoq8Qg1VCAfg=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
  FeaturedYoutubeChannel(
    title: 'Veena Rajasthani Khana Khazana',
    subscribers: '2.92K subscribers',
    handle: '@veenarajasthanikhanakhazan5154',
    url: 'https://www.youtube.com/@veenarajasthanikhanakhazan5154',
    avatarUrl:
        'https://yt3.googleusercontent.com/ytc/AIdro_krHaqYLKITsR_p4hcnsI4M3F4Z8Lflgjo7szaBUxxxPg=s176-c-k-c0x00ffffff-no-rj-mo',
  ),
];

class FeaturedYoutubeChannelsSection extends StatelessWidget {
  const FeaturedYoutubeChannelsSection({
    super.key,
    this.channels = featuredYoutubeChannels,
  });

  final List<FeaturedYoutubeChannel> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Featured YT Channels'),
          SizedBox(
            height: 214,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: channels.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final channel = channels[index];
                return _FeaturedYoutubeChannelCard(
                  channel: channel,
                  isDark: isDark,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _FeaturedYoutubeChannelCard extends StatelessWidget {
  const _FeaturedYoutubeChannelCard({
    required this.channel,
    required this.isDark,
  });

  final FeaturedYoutubeChannel channel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAvatarUrl = _buildPrimaryAvatarUrl(channel.handle);

    return GestureDetector(
      onTap: () => openUrl(channel.url),
      child: Container(
        width: 144,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
          // border: Border.all(
          //   color: theme.colorScheme.outlineVariant.withOpacity(0.45),
          // ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.22),
                    AppColors.primary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child: AppNetworkImage(
                  imageUrl: primaryAvatarUrl,
                  fallbackImageUrl: channel.avatarUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 220,
                  placeholder: Container(
                    color: theme.colorScheme.surface,
                    child: const Icon(Icons.play_circle_fill_rounded),
                  ),
                  errorChild: Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Text(
                        _initials(channel.title),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              channel.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.subscribers,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPrimaryAvatarUrl(String handle) {
    final normalizedHandle = handle.replaceAll('@', '').trim();
    return 'https://unavatar.io/youtube/$normalizedHandle';
  }

  String _initials(String value) {
    final tokens = value.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return '?';
    if (tokens.length == 1) {
      return tokens.first.substring(0, 1).toUpperCase();
    }
    return tokens.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
