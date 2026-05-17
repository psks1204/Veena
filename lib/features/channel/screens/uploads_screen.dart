import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/media_item.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/count_formatter.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../player/widgets/comments_sheet.dart';
import '../models/channel.dart' as channel_models;
import 'channel_reels_screen.dart';
import 'public_channel_screen.dart';
import '../services/channel_interaction_service.dart';
import '../services/channel_service.dart';

/// Feed screen — vertical-scroll reels UI.
///
/// Playback is fully independent of PlayerProvider; each reel owns its
/// own VideoPlayerController so the mini-player / main queue are unaffected.
class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  static VoidCallback? _pauseActiveReel;

  static void pauseReelPlayback() {
    _pauseActiveReel?.call();
  }

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final PageController _pageController = PageController();
  final List<channel_models.UserMediaResponse> _items = [];
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<String, bool> _showHeartBurst = {};

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _feedPage = 0;

  @override
  void initState() {
    super.initState();
    UploadsScreen._pauseActiveReel = _pauseAllControllers;
    _loadMore(refresh: true);
    _pageController.addListener(_onScrollListener);
  }

  @override
  void dispose() {
    if (UploadsScreen._pauseActiveReel == _pauseAllControllers) {
      UploadsScreen._pauseActiveReel = null;
    }
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    _pauseAllControllers();
    super.deactivate();
  }

  void _onScrollListener() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round() ?? 0;
    if (_items.isNotEmpty && page >= _items.length - 3) {
      _loadMore();
    }
  }

  void _onPageChanged(int page) {
    _controllers[_currentPage]?.pause();
    setState(() => _currentPage = page);
    unawaited(_primeLikeStatus(page));
    unawaited(_primeLikeStatus(page + 1));
    final c = _controllers[page];
    if (c != null && c.value.isInitialized) {
      c.play();
      unawaited(_recordPlay(page));
    } else {
      unawaited(_initController(page));
    }
    unawaited(_initController(page + 1));
    _controllers.keys.where((k) => (k - page).abs() > 2).toList().forEach((k) {
      final mediaId = (k >= 0 && k < _items.length) ? _items[k].id : null;
      _controllers[k]?.dispose();
      _controllers.remove(k);
      if (mediaId != null) {
        context.read<ChannelInteractionService>().removeMediaState(mediaId);
      }
    });
  }

  Future<void> _primeLikeStatus(int index) async {
    if (index < 0 || index >= _items.length) return;
    await context.read<ChannelInteractionService>().checkLikeStatus(
      _items[index].id,
    );
  }

  Future<void> _initController(int index) async {
    if (index < 0 || index >= _items.length) return;
    if (_controllers.containsKey(index)) return;
    final item = _items[index];
    final url = item.hlsUrl;
    if (url == null || url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controllers[index] = controller;
    await controller.initialize();
    controller.setLooping(true);
    if (!mounted) return;
    if (index == _currentPage) {
      await controller.play();
      unawaited(_recordPlay(index));
    }
    if (mounted) setState(() {});
  }

  Future<void> _recordPlay(int index) async {
    if (index < 0 || index >= _items.length) return;
    await context.read<ChannelInteractionService>().recordPlay(
      _items[index].id,
    );
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        for (final c in _controllers.values) {
          c.dispose();
        }
        _controllers.clear();
        _items.clear();
        _hasMore = true;
        _feedPage = 0;
        _currentPage = 0;
      }
    });
    try {
      final result = await context.read<ChannelService>().getPublicFeed(
        page: _feedPage,
      );
      if (!mounted) return;
      final oldLength = _items.length;
      setState(() {
        _items.addAll(result.content);
        _hasMore = !result.isLast;
        _feedPage++;
      });
      if (refresh && _items.isNotEmpty) {
        unawaited(_initController(0));
        if (_items.length > 1) unawaited(_initController(1));
        unawaited(_primeLikeStatus(0));
        unawaited(_primeLikeStatus(1));
      } else {
        for (
          int i = oldLength;
          i < (oldLength + 2).clamp(0, _items.length);
          i++
        ) {
          unawaited(_initController(i));
          unawaited(_primeLikeStatus(i));
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load feed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  MediaItem _toMediaItem(channel_models.UserMediaResponse item) {
    return MediaItem(
      id: item.id,
      title: item.title,
      description: item.description,
      mediaType: item.mediaType == channel_models.MediaType.video
          ? MediaType.video
          : MediaType.audio,
      status: item.status == channel_models.MediaStatus.ready
          ? MediaStatus.published
          : MediaStatus.processing,
      hlsUrl: item.hlsUrl,
      thumbnailUrl: item.thumbnailUrl,
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.updatedAt ?? DateTime.now(),
      playedCount: item.playCount,
      isChannelMedia: true,
      artist: ArtistInfo(
        id: 0,
        name: (item.uploadedByName ?? item.channelName ?? 'Veena Creator')
            .trim(),
      ),
    );
  }

  Future<void> _toggleLike(
    channel_models.UserMediaResponse item,
    ChannelInteractionService svc, {
    bool forceLike = false,
  }) async {
    final liked = svc.isLiked(item.id);
    if (!(forceLike && liked)) {
      await svc.toggleLike(item.id, initial: liked);
    }
    if (!mounted) return;
    setState(() => _showHeartBurst[item.id] = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeartBurst.remove(item.id));
    });
  }

  Future<void> _openComments(MediaItem media) async {
    final enabled = context.read<AppSettingsService>().enableComments;
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comments are currently disabled')),
      );
      return;
    }
    _controllers[_currentPage]?.pause();
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CommentsSheet(mediaId: media.id, source: CommentsSource.channel),
    );
    if (mounted) _controllers[_currentPage]?.play();
  }

  Future<void> _openAddToPlaylist(MediaItem media) async {
    _controllers[_currentPage]?.pause();
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(mediaItem: media),
    );
    if (mounted) _controllers[_currentPage]?.play();
  }

  Future<void> _share(MediaItem media) async {
    final url = 'https://veenamusiconline.com/song/${media.id}';
    await Share.share('Listen to "${media.title}" on Veena Music: $url');
  }

  Future<void> _openCreatorChannel(
    channel_models.UserMediaResponse item,
  ) async {
    final channelId = item.channelId;
    if (channelId == null || channelId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Channel not available')));
      return;
    }

    _pauseAllControllers();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicChannelScreen(
          channelId: channelId,
          channelName: item.channelName ?? item.uploadedByName,
        ),
      ),
    );
  }

  void _pauseAllControllers() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactionService = context.watch<ChannelInteractionService>();

    if (_items.isEmpty && _isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feed')),
        body: const Center(child: Text('No approved media in feed yet')),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Feed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const PageScrollPhysics(),
          itemCount: _hasMore ? _items.length + 1 : _items.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final item = _items[index];
            final media = _toMediaItem(item);
            final controller = _controllers[index];
            final isVideo = item.mediaType == channel_models.MediaType.video;
            final isLiked = interactionService.isLiked(item.id);
            final likeCount = interactionService.getLikeCount(item.id);
            final showBurst = _showHeartBurst[item.id] == true;
            if (controller == null) unawaited(_initController(index));
            return _ReelPage(
              item: item,
              media: media,
              controller: controller,
              isVideo: isVideo,
              isLiked: isLiked,
              likeCount: likeCount,
              playCount: item.playCount,
              showHeartBurst: showBurst,
              onDoubleTap: () =>
                  _toggleLike(item, interactionService, forceLike: true),
              onLike: () => _toggleLike(item, interactionService),
              onComment: () => _openComments(media),
              onShare: () => _share(media),
              onAddToPlaylist: () => _openAddToPlaylist(media),
              onArtistTap: () => _openCreatorChannel(item),
            );
          },
        ),
      ),
    );
  }
}

// ─── Reel page ────────────────────────────────────────────────────────────────

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    required this.item,
    required this.media,
    required this.controller,
    required this.isVideo,
    required this.isLiked,
    required this.likeCount,
    required this.playCount,
    required this.showHeartBurst,
    required this.onDoubleTap,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAddToPlaylist,
    required this.onArtistTap,
  });

  final channel_models.UserMediaResponse item;
  final MediaItem media;
  final VideoPlayerController? controller;
  final bool isVideo;
  final bool isLiked;
  final int likeCount;
  final int playCount;
  final bool showHeartBurst;
  final VoidCallback onDoubleTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onArtistTap;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  bool _showPauseIcon = false;
  Timer? _pauseIconTimer;

  void _onTap() {
    final c = widget.controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _showPauseIcon = true);
      _pauseIconTimer?.cancel();
      _pauseIconTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showPauseIcon = false);
      });
    } else {
      c.play();
      setState(() => _showPauseIcon = false);
    }
  }

  @override
  void dispose() {
    _pauseIconTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isReady = c != null && c.value.isInitialized;
    final bottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: isReady && widget.isVideo
                ? _VideoBackground(controller: c!)
                : _ThumbnailBackground(
                    media: widget.media,
                    isVideo: widget.isVideo,
                  ),
          ),
          if (!widget.isVideo && isReady) _AudioPulse(controller: c!),
          if (_showPauseIcon)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          if (widget.showHeartBurst)
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 92,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 80,
            bottom: bottom + 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.media.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: widget.onArtistTap,
                  child: Text(
                    widget.media.artistName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if ((widget.media.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.media.description!.trim(),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: bottom + 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EngagementCountBadge(
                  playCount: widget.playCount,
                  likeCount: widget.likeCount,
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: widget.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: widget.isLiked ? Colors.redAccent : Colors.white,
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  onTap: widget.onShare,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.playlist_add_rounded,
                  color: Colors.white,
                  onTap: widget.onAddToPlaylist,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _VideoBackground extends StatelessWidget {
  const _VideoBackground({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _ThumbnailBackground extends StatelessWidget {
  const _ThumbnailBackground({required this.media, required this.isVideo});

  final MediaItem media;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final thumb = media.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _PlaceholderIcon(isVideo: isVideo),
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
        color: Colors.white24,
        size: 80,
      ),
    );
  }
}

class _AudioPulse extends StatefulWidget {
  const _AudioPulse({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_AudioPulse> createState() => _AudioPulseState();
}

class _AudioPulseState extends State<_AudioPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    widget.controller.addListener(_onControllerChanged);
    _updateAnimation();
  }

  @override
  void dispose() {
    _anim.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => _updateAnimation();

  void _updateAnimation() {
    if (!mounted) return;
    if (widget.controller.value.isPlaying) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      _anim.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Container(
          width: 80 + 40 * _anim.value,
          height: 80 + 40 * _anim.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: (1 - _anim.value) * 0.6,
              ),
              width: 2,
            ),
          ),
          child: child,
        ),
        child: const Center(
          child: Icon(
            Icons.music_note_rounded,
            color: Colors.white70,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                shadows: [Shadow(blurRadius: 3, color: Colors.black87)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EngagementCountBadge extends StatelessWidget {
  const _EngagementCountBadge({
    required this.playCount,
    required this.likeCount,
  });

  final int playCount;
  final int likeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            formatCompactCount(playCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '·',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.favorite_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            formatCompactCount(likeCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
