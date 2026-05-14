import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/count_formatter.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../player/widgets/comments_sheet.dart';
import '../models/channel.dart' as channel_models;
import '../providers/channel_provider.dart';
import '../services/channel_interaction_service.dart';
import '../services/channel_service.dart';
import 'channel_reels_screen.dart';
import 'upload_media_screen.dart';

/// My Channel Screen
///
/// Shows channel profile/edit controls plus a feed with status filters:
/// All, Approved, Pending, Rejected.
enum _MyChannelTab { all, approved, pending, rejected }

class MyChannelScreen extends StatefulWidget {
  const MyChannelScreen({super.key});

  @override
  State<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends State<MyChannelScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<channel_models.UserMediaResponse> _feedItems = [];
  final Map<String, bool> _showHeartBurst = {};

  channel_models.ChannelResponse? _channelSnapshot;
  _MyChannelTab _activeTab = _MyChannelTab.all;
  bool _feedLoading = false;
  bool _feedHasMore = true;
  int _feedPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChannelAndFeed(refresh: true);
    });
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
      _loadChannelAndFeed();
    }
  }

  String? _approvalStatusForTab(_MyChannelTab tab) {
    switch (tab) {
      case _MyChannelTab.approved:
        return 'APPROVED';
      case _MyChannelTab.pending:
        return 'PENDING';
      case _MyChannelTab.rejected:
        return 'REJECTED';
      case _MyChannelTab.all:
        return null;
    }
  }

  void _onTabChanged(_MyChannelTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _loadChannelAndFeed(refresh: true);
  }

  Future<void> _loadChannelAndFeed({bool refresh = false}) async {
    if (_feedLoading) return;
    if (!refresh && !_feedHasMore) return;

    setState(() {
      _feedLoading = true;
      if (refresh) {
        _feedItems.clear();
        _feedHasMore = true;
        _feedPage = 0;
      }
    });

    try {
      final provider = context.read<ChannelProvider>();
      final channelService = context.read<ChannelService>();
      channel_models.ChannelResponse? channel = provider.channel;

      if (channel == null) {
        await provider.initializeOnLogin();
        channel = provider.channel;
      }

      channel ??= _channelSnapshot;

      // Fallback so this screen still works if provider was not hydrated yet.
      channel ??= await channelService.getOrCreateChannel();

      final result = await channelService.getMyMedia(
        status: _approvalStatusForTab(_activeTab),
        page: _feedPage,
      );

      if (!mounted) return;
      setState(() {
        _channelSnapshot = channel;
        _feedItems.addAll(result.content);
        _feedHasMore = !result.isLast;
        _feedPage++;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load channel feed')),
      );
    } finally {
      if (mounted) {
        setState(() => _feedLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );
    if (image == null || !mounted) return;

    final provider = context.read<ChannelProvider>();
    bool success;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      success = await provider.uploadChannelImage(
        bytes: bytes,
        fileName: image.name,
      );
    } else {
      success = await provider.uploadChannelImage(filePath: image.path);
    }

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to upload image'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      _loadChannelAndFeed(refresh: true);
    }
  }

  void _navigateToUpload(channel_models.MediaType type) {
    context.read<ChannelProvider>().resetUploadState();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadMediaScreen(initialMediaType: type),
      ),
    );
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
    unawaited(context.read<ChannelInteractionService>().recordPlay(item.id));
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
    ChannelInteractionService interactionService, {
    bool forceLike = false,
  }) async {
    final currentlyLiked = interactionService.isLiked(item.id);
    if (!(forceLike && currentlyLiked)) {
      await interactionService.toggleLike(item.id, initial: currentlyLiked);
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
      builder: (_) =>
          CommentsSheet(mediaId: media.id, source: CommentsSource.channel),
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

  void _showUploadPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.screenPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: const Icon(
                    Icons.audio_file_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Upload Music'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToUpload(channel_models.MediaType.audio);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.video_file_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Upload Video'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToUpload(channel_models.MediaType.video);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditChannelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChannelProvider>(),
        child: const _EditChannelSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();
    final interactionService = context.watch<ChannelInteractionService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final gridColumns = _gridColumnsForWidth(
      screenWidth - (AppSpacing.screenPadding * 2),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('My Channel', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Upload',
            onPressed: _showUploadPicker,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit channel',
            onPressed: () => _showEditChannelSheet(context),
          ),
        ],
      ),
      body: Consumer<ChannelProvider>(
        builder: (context, provider, _) {
          final channel = provider.channel ?? _channelSnapshot;

          return RefreshIndicator(
            onRefresh: () => _loadChannelAndFeed(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChannelHeader(
                          channel: channel,
                          isDark: isDark,
                          onEditImage: _pickAndUploadImage,
                          isLoading: provider.isLoading,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('My Feed', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        _MyChannelTabChips(
                          selectedTab: _activeTab,
                          onTabSelected: _onTabChanged,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                if (_feedLoading && _feedItems.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_feedItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFeed(activeTab: _activeTab),
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
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: _feedItems.length + (_feedLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _feedItems.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final item = _feedItems[index];
                        final isVideo =
                            item.mediaType == channel_models.MediaType.video;
                        return GestureDetector(
                          onTap: () => _onTapGridItem(index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _GridThumbnail(
                                  thumbnailUrl: item.thumbnailUrl,
                                  isVideo: isVideo,
                                ),
                                Positioned(
                                  left: 4,
                                  bottom: 4,
                                  child: Icon(
                                    isVideo
                                        ? Icons.videocam_rounded
                                        : Icons.music_note_rounded,
                                    color: Colors.white,
                                    size: 16,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 3,
                                        color: Colors.black87,
                                      ),
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
                                        formatCompactCount(item.playCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 3,
                                              color: Colors.black87,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: _ApprovalBadge(
                                    status: item.approvalStatus,
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
          );
        },
      ),
    );
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1500) return 7;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 700) return 4;
    return 3;
  }
}

// Grid helpers extracted to keep build clean
extension on _MyChannelScreenState {
  Future<void> _onTapGridItem(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelReelsScreen.myChannel(
          channelName: _channelSnapshot?.channelName,
          approvalStatus: _approvalStatusForTab(_activeTab),
          initialIndex: index,
          seedItems: List<channel_models.UserMediaResponse>.from(_feedItems),
          seedHasMore: _feedHasMore,
          seedPage: _feedPage,
        ),
      ),
    );

    if (!mounted) return;
    _loadChannelAndFeed(refresh: true);
  }
}

// ─── New grid / detail helpers ───────────────────────────────────────────────

// Placeholder: keep old code temporarily in a dead class to locate the end.
class _GridThumbnail extends StatelessWidget {
  const _GridThumbnail({required this.thumbnailUrl, required this.isVideo});

  final String? thumbnailUrl;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(
        thumbnailUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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

class _MediaDetailSheet extends StatelessWidget {
  const _MediaDetailSheet({
    required this.item,
    required this.media,
    required this.player,
    required this.interactionService,
    required this.onPlay,
    required this.onFullscreen,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAddToPlaylist,
  });

  final channel_models.UserMediaResponse item;
  final MediaItem media;
  final PlayerProvider player;
  final ChannelInteractionService interactionService;
  final VoidCallback onPlay;
  final VoidCallback onFullscreen;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCurrent = player.currentMedia?.id == item.id;
    final isPlaying = isCurrent && player.isPlaying;
    final isLiked = interactionService.isLiked(item.id);
    final isVideo = item.mediaType == channel_models.MediaType.video;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        media.artistName,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _ApprovalBadge(status: item.approvalStatus),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPlay();
                  },
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                if (isVideo)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onFullscreen();
                    },
                    tooltip: 'Fullscreen',
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onLike,
                  tooltip: 'Like',
                  icon: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? AppColors.error : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onComment();
                  },
                  tooltip: 'Comments',
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                IconButton(
                  onPressed: onShare,
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToPlaylist();
                  },
                  tooltip: 'Add to playlist',
                  icon: const Icon(Icons.playlist_add_rounded),
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
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.channel,
    required this.isDark,
    required this.onEditImage,
    required this.isLoading,
  });

  final channel_models.ChannelResponse? channel;
  final bool isDark;
  final VoidCallback onEditImage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onEditImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: channel?.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: channel!.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _placeholder(80),
                        errorWidget: (context, url, error) => _placeholder(80),
                      )
                    : _placeholder(80),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel?.channelName ?? 'My Channel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (channel?.channelHandle != null)
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
                  _Stat(
                    value: '${channel?.totalMedia ?? 0}',
                    label: 'uploads',
                    isDark: isDark,
                  ),
                  _Stat(
                    value: '${channel?.subscriberCount ?? 0}',
                    label: 'subscribers',
                    isDark: isDark,
                  ),
                  _Stat(
                    value: '${channel?.totalViews ?? 0}',
                    label: 'views',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.isDark});
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _MyChannelTabChips extends StatelessWidget {
  const _MyChannelTabChips({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _MyChannelTab selectedTab;
  final ValueChanged<_MyChannelTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_MyChannelTab.all, 'All'),
      (_MyChannelTab.approved, 'Approved'),
      (_MyChannelTab.pending, 'Pending'),
      (_MyChannelTab.rejected, 'Rejected'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = tabs[index].$1;
          final label = tabs[index].$2;
          return ChoiceChip(
            label: Text(label),
            selected: tab == selectedTab,
            onSelected: (_) => onTabSelected(tab),
            selectedColor: AppColors.primary.withValues(alpha: 0.22),
            side: BorderSide(
              color: tab == selectedTab
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.status});

  final channel_models.ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      channel_models.ApprovalStatus.approved => ('APPROVED', AppColors.success),
      channel_models.ApprovalStatus.rejected => ('REJECTED', AppColors.error),
      channel_models.ApprovalStatus.pending => (
        'PENDING',
        const Color(0xFFFFB300),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.activeTab});

  final _MyChannelTab activeTab;

  String get _title {
    switch (activeTab) {
      case _MyChannelTab.approved:
        return 'No approved media yet';
      case _MyChannelTab.pending:
        return 'No pending media yet';
      case _MyChannelTab.rejected:
        return 'No rejected media yet';
      case _MyChannelTab.all:
        return 'No media yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.dynamic_feed_rounded,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Upload content and manage it by status here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EditChannelSheet extends StatefulWidget {
  const _EditChannelSheet();

  @override
  State<_EditChannelSheet> createState() => _EditChannelSheetState();
}

class _EditChannelSheetState extends State<_EditChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final channel = context.read<ChannelProvider>().channel;
    _nameController.text = channel?.channelName ?? '';
    _handleController.text = channel?.channelHandle ?? '';
    _descController.text = channel?.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ChannelProvider>();
    final ok = await provider.updateChannel(
      channelName: _nameController.text.trim(),
      channelHandle: _handleController.text.trim().isEmpty
          ? null
          : _handleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Channel', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Channel name'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(
                  labelText: 'Handle (optional)',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              Consumer<ChannelProvider>(
                builder: (context, provider, _) => FilledButton(
                  onPressed: provider.isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
