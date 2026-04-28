import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../player/widgets/comments_sheet.dart';
import '../models/channel.dart' as channel_models;
import '../services/channel_service.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<channel_models.UserMediaResponse> _items = [];
  final Map<String, bool> _showHeartBurst = {};

  bool _isLoading = false;
  bool _hasMore = true;
  final String _statusFilter = 'APPROVED';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadMore(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _items.clear();
        _hasMore = true;
        _page = 0;
      }
    });

    try {
      final result = await context.read<ChannelService>().getMyMedia(
        approvalStatus: _statusFilter,
        page: _page,
      );
      final approvedItems = result.content.where((item) {
        return item.approvalStatus == channel_models.ApprovalStatus.approved;
      }).toList();

      if (!mounted) return;
      setState(() {
        _items.addAll(approvedItems);
        _hasMore = !result.isLast;
        _page++;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load feed')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  MediaItem _toMediaItem(channel_models.UserMediaResponse item) {
    final mediaType = item.mediaType == channel_models.MediaType.video
        ? MediaType.video
        : MediaType.audio;

    final status = item.status == channel_models.MediaStatus.ready
        ? MediaStatus.published
        : MediaStatus.processing;

    return MediaItem(
      id: item.id,
      title: item.title,
      description: item.description,
      mediaType: mediaType,
      status: status,
      hlsUrl: item.hlsUrl,
      thumbnailUrl: item.thumbnailUrl,
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.updatedAt ?? DateTime.now(),
      playedCount: item.playCount,
      artist: ArtistInfo(
        id: 0,
        name: (item.uploadedByName ?? item.channelName ?? 'Veena Creator')
            .trim(),
      ),
    );
  }

  Future<void> _playItem(channel_models.UserMediaResponse item) async {
    final media = _toMediaItem(item);
    if (media.hlsUrl == null || media.hlsUrl!.isEmpty) return;
    await context.read<PlayerProvider>().play(media);
  }

  Future<void> _onTapMedia(
    channel_models.UserMediaResponse item,
    PlayerProvider player,
  ) async {
    final isCurrent = player.currentMedia?.id == item.id;
    if (isCurrent) {
      await player.togglePlayPause();
      return;
    }
    await _playItem(item);
  }

  Future<void> _toggleLike(
    channel_models.UserMediaResponse item,
    MediaService mediaService, {
    bool forceLike = false,
  }) async {
    final currentlyLiked = mediaService.isLiked(item.id);
    if (!(forceLike && currentlyLiked)) {
      await mediaService.toggleLike(item.id, initial: currentlyLiked);
    }
    if (!mounted) return;
    setState(() => _showHeartBurst[item.id] = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _showHeartBurst.remove(item.id));
    });
  }

  Future<void> _share(MediaItem media) async {
    final shareUrl = 'https://veenamusiconline.com/song/${media.id}';
    await Share.share(
      'Listen to "${media.title}" on Veena Music: $shareUrl',
      subject: 'Share Song',
    );
  }

  Future<void> _openComments(MediaItem media) async {
    final commentsEnabled = context.read<AppSettingsService>().enableComments;
    if (!commentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comments are currently disabled')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(mediaId: media.id),
    );
  }

  Future<void> _openAddToPlaylist(MediaItem media) async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(mediaItem: media),
    );
  }

  Future<void> _openFullscreen(channel_models.UserMediaResponse item) async {
    final player = context.read<PlayerProvider>();
    final isCurrent = player.currentMedia?.id == item.id;
    if (!isCurrent) {
      await _playItem(item);
    }
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<PlayerProvider>();
    final mediaService = context.watch<MediaService>();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.brightness == Brightness.dark
                ? AppColors.darkBg
                : AppColors.lightBg,
            title: Text(
              'Feed',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_items.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No approved media in feed yet')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: 140,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  final item = _items[index];
                  final media = _toMediaItem(item);
                  final isCurrent = player.currentMedia?.id == item.id;
                  final isPlaying = isCurrent && player.isPlaying;
                  final isLiked = mediaService.isLiked(item.id);

                  final isVideo =
                      item.mediaType == channel_models.MediaType.video;
                  final videoController = player.videoController;
                  final showVideo =
                      isVideo &&
                      isCurrent &&
                      videoController != null &&
                      videoController.value.isInitialized;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: kIsWeb ? 760 : double.infinity,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          media.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          media.artistName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      MediaOptionsSheet.show(
                                        context,
                                        mediaItem: media,
                                      );
                                    },
                                    icon: const Icon(Icons.more_vert_rounded),
                                  ),
                                ],
                              ),
                            ),
                            _FeedMediaSurface(
                              media: media,
                              isVideo: isVideo,
                              isPlaying: isPlaying,
                              showVideo: showVideo,
                              videoController: videoController,
                              showHeartBurst: _showHeartBurst[item.id] == true,
                              onTap: () => _onTapMedia(item, player),
                              onDoubleTap: () => _toggleLike(
                                item,
                                mediaService,
                                forceLike: true,
                              ),
                              onFullscreenTap: isVideo
                                  ? () => _openFullscreen(item)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _toggleLike(item, mediaService),
                                    tooltip: 'Like',
                                    icon: Icon(
                                      isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isLiked ? AppColors.error : null,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _openComments(media),
                                    tooltip: 'Comment',
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _share(media),
                                    tooltip: 'Share',
                                    icon: const Icon(Icons.share_rounded),
                                  ),
                                  IconButton(
                                    onPressed: () => _openAddToPlaylist(media),
                                    tooltip: 'Add to playlist',
                                    icon: const Icon(
                                      Icons.playlist_add_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((media.description ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                ),
                                child: Text(
                                  media.description!.trim(),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: _items.length + 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedMediaSurface extends StatelessWidget {
  const _FeedMediaSurface({
    required this.media,
    required this.isVideo,
    required this.isPlaying,
    required this.showVideo,
    required this.videoController,
    required this.showHeartBurst,
    required this.onTap,
    required this.onDoubleTap,
    this.onFullscreenTap,
  });

  final MediaItem media;
  final bool isVideo;
  final bool isPlaying;
  final bool showVideo;
  final VideoPlayerController? videoController;
  final bool showHeartBurst;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onFullscreenTap;

  @override
  Widget build(BuildContext context) {
    final isWebAudio = kIsWeb && !isVideo;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AspectRatio(
        aspectRatio: isVideo
            ? (showVideo
                  ? (videoController!.value.aspectRatio > 0
                        ? videoController!.value.aspectRatio
                        : (16 / 9))
                  : (16 / 9))
            : (isWebAudio ? (16 / 9) : (1 / 1)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black,
              child: showVideo
                  ? VideoPlayer(videoController!)
                  : _FallbackArtwork(media: media, isVideo: isVideo),
            ),
            if (showHeartBurst)
              const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 92,
                ),
              ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
            if (onFullscreenTap != null)
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: IconButton.filledTonal(
                  onPressed: onFullscreenTap,
                  icon: const Icon(Icons.fullscreen_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork({required this.media, required this.isVideo});

  final MediaItem media;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final thumbnail = media.thumbnailUrl;

    if (thumbnail != null && thumbnail.isNotEmpty) {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            _PlaceholderIcon(isVideo: isVideo),
      );
    }

    return _PlaceholderIcon(isVideo: isVideo);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isVideo ? Icons.video_library_rounded : Icons.music_note_rounded,
        color: Colors.white70,
        size: 68,
      ),
    );
  }
}
