import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/channel.dart' as channel_models;
import '../services/channel_service.dart';
import 'channel_reels_screen.dart';

class PublicChannelScreen extends StatefulWidget {
  const PublicChannelScreen({
    super.key,
    required this.channelId,
    this.channelName,
  });

  final String channelId;
  final String? channelName;

  @override
  State<PublicChannelScreen> createState() => _PublicChannelScreenState();
}

class _PublicChannelScreenState extends State<PublicChannelScreen> {
  final List<channel_models.UserMediaResponse> _items = [];

  channel_models.ChannelResponse? _channel;
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadChannelAndMedia(refresh: true);
  }

  Future<void> _loadChannelAndMedia({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _items.clear();
        _page = 0;
        _hasMore = true;
      }
    });

    try {
      final service = context.read<ChannelService>();
      final futures = await Future.wait([
        service.getPublicChannel(widget.channelId),
        service.getPublicChannelMedia(widget.channelId, page: _page),
      ]);

      final channel = futures[0] as channel_models.ChannelResponse;
      final media = futures[1] as dynamic;

      if (!mounted) return;
      setState(() {
        _channel = channel;
        _items.addAll(media.content as List<channel_models.UserMediaResponse>);
        _hasMore = !(media.isLast as bool);
        _page++;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load channel')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _crossAxisCountForWidth(double width) {
    if (width >= 1500) return 7;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 700) return 4;
    return 3;
  }

  Future<void> _openReelsAt(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelReelsScreen.publicChannel(
          channelId: widget.channelId,
          channelName: _channel?.channelName ?? widget.channelName,
          initialIndex: index,
          seedItems: List<channel_models.UserMediaResponse>.from(_items),
          seedHasMore: _hasMore,
          seedPage: _page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final columns = _crossAxisCountForWidth(width - (AppSpacing.screenPadding * 2));

    return Scaffold(
      appBar: AppBar(
        title: Text(_channel?.channelName ?? widget.channelName ?? 'Channel'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadChannelAndMedia(refresh: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: _PublicChannelHeader(
                  channel: _channel,
                  isDark: isDark,
                ),
              ),
            ),
            if (_isLoading && _items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No reels available yet')),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: _items.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final item = _items[index];
                    final isVideo = item.mediaType == channel_models.MediaType.video;

                    return GestureDetector(
                      onTap: () => _openReelsAt(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _GridThumb(
                              thumbnailUrl: item.thumbnailUrl,
                              isVideo: isVideo,
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Icon(
                                isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.music_note_rounded,
                                color: Colors.white,
                                size: 16,
                                shadows: const [
                                  Shadow(blurRadius: 3, color: Colors.black87),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.playCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(blurRadius: 3, color: Colors.black87),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicChannelHeader extends StatelessWidget {
  const _PublicChannelHeader({required this.channel, required this.isDark});

  final channel_models.ChannelResponse? channel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: channel?.imageUrl != null && channel!.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: channel!.imageUrl!,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel?.channelName ?? 'Channel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (channel?.channelHandle != null &&
                  channel!.channelHandle!.trim().isNotEmpty)
                Text(
                  '@${channel!.channelHandle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _Stat(value: '${channel?.approvedMedia ?? 0}', label: 'reels'),
                  _Stat(value: '${channel?.subscriberCount ?? 0}', label: 'subs'),
                  _Stat(value: '${channel?.totalViews ?? 0}', label: 'views'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Icon(Icons.person_rounded, color: AppColors.primary),
    );
  }
}

class _GridThumb extends StatelessWidget {
  const _GridThumb({required this.thumbnailUrl, required this.isVideo});

  final String? thumbnailUrl;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(
        thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.music_note_rounded,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
