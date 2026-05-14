import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/models/media_item.dart';
import '../../core/models/artist.dart';
import 'web_video_fullscreen.dart';
import 'lyrics_card.dart';
import '../../core/services/artist_service.dart';
import '../../core/services/library_service.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/media_service.dart';
import '../../features/library/screens/artist_detail_screen.dart';
import '../../features/player/widgets/comments_sheet.dart';
import 'share_song_button.dart';

/// Spotify-style Now Playing Panel
///
/// Right-side panel showing current track artwork, info, queue, and inline video.
class NowPlayingPanel extends StatefulWidget {
  const NowPlayingPanel({super.key, this.onClose, this.onTabChanged});

  final VoidCallback? onClose;
  final ValueChanged<bool>?
  onTabChanged; // Called with true when Queue tab opens

  @override
  State<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends State<NowPlayingPanel> {
  // 0 = Track Details, 1 = Queue
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Subscribe to fullscreen state changes to trigger rebuild
    // This ensures we hide/show VideoPlayer correctly
    WebVideoFullscreen.onStateChanged = _onFullscreenStateChanged;
  }

  @override
  void dispose() {
    // Clean up listener
    if (WebVideoFullscreen.onStateChanged == _onFullscreenStateChanged) {
      WebVideoFullscreen.onStateChanged = null;
    }
    super.dispose();
  }

  void _onFullscreenStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Formats large numbers (e.g., 1234 -> "1.2K", 1234567 -> "1.2M")
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : AppColors.lightSurface;

    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasMedia) {
          return _buildEmptyState(isDark);
        }

        final media = player.currentMedia!;

        return Container(
          width: 340,
          color: backgroundColor,
          child: Column(
            children: [
              // Header
              _buildHeader(media, isDark),

              // Tabs (Details / Queue)
              _buildTabs(isDark),

              // Content
              Expanded(
                child: _tabIndex == 0
                    ? _buildDetailsView(player, media, isDark)
                    : _buildQueueView(player, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: 340,
      color: isDark ? const Color(0xFF121212) : AppColors.lightSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black12,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Play something to see it here',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MediaItem media, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              media.album?.name ?? media.title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (context.watch<AppSettingsService>().enableComments)
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CommentsSheet(mediaId: media.id),
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                size: 20,
              ),
              tooltip: 'Comments',
              splashRadius: 18,
            ),
          ShareSongButton(
            media: media,
            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
            size: 20,
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              size: 20,
            ),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                final player = context.read<PlayerProvider>();
                final wasPlaying = player.isPlaying;

                setState(() => _tabIndex = 0);
                widget.onTabChanged?.call(false);

                if (wasPlaying && player.videoController != null) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted && !player.videoController!.value.isPlaying) {
                      player.videoController!.play();
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _tabIndex == 0
                      ? (isDark ? const Color(0xFF3E3E3E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _tabIndex == 0 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Details',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : (_tabIndex == 0
                                ? AppColors.lightTextPrimary
                                : AppColors.lightTextSecondary),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final player = context.read<PlayerProvider>();
                final wasPlaying = player.isPlaying;

                setState(() => _tabIndex = 1);
                widget.onTabChanged?.call(true);

                if (wasPlaying && player.videoController != null) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted && !player.videoController!.value.isPlaying) {
                      player.videoController!.play();
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _tabIndex == 1
                      ? (isDark ? const Color(0xFF3E3E3E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _tabIndex == 1 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Queue',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : (_tabIndex == 1
                                ? AppColors.lightTextPrimary
                                : AppColors.lightTextSecondary),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView(
    PlayerProvider player,
    MediaItem media,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork or Video Player
          _buildMediaContent(player, media),

          const SizedBox(height: 16),

          // Switch Button
          if (media.linkedMedia != null)
            _buildSwitchButton(player, media, isDark),

          if (media.linkedMedia != null) const SizedBox(height: 16),

          // Lyrics Card
          if (player.currentLyrics != null)
            LyricsCard(
              lyrics: player.currentLyrics!,
              activeIndex: player.activeLyricIndex,
            ),

          if (player.currentLyrics != null) const SizedBox(height: 20),

          // Track Info
          Text(
            media.title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            media.artistName,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          _buildEngagementStats(media, isDark),

          const SizedBox(height: 10),

          // Credits Section
          _buildCreditsSection(media, isDark),

          const SizedBox(height: 24),

          // Artist Section
          _buildArtistSection(media, isDark),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEngagementStats(MediaItem media, bool isDark) {
    final iconColor = isDark
        ? Colors.white.withOpacity(0.75)
        : AppColors.lightTextSecondary;

    return Consumer<MediaService>(
      builder: (context, mediaService, _) {
        final likeCount = mediaService.getLikeCount(
          media.id,
          initial: media.likeCount,
        );

        return Row(
          children: [
            Icon(Icons.play_arrow_rounded, size: 14, color: iconColor),
            const SizedBox(width: 2),
            Text(
              _formatCount(media.playedCount),
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '·',
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.favorite_rounded, size: 12, color: iconColor),
            const SizedBox(width: 3),
            Text(
              _formatCount(likeCount),
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaContent(PlayerProvider player, MediaItem media) {
    // IMPORTANT: Only ONE VideoPlayer should exist in the entire widget tree at any time
    // On Flutter Web, multiple VideoPlayers with same controller cause DOM conflicts
    final isFullscreen = WebVideoFullscreen.isFullscreenActive;
    final hasVideoController = media.isVideo && player.videoController != null;
    final isVideoInitialized =
        hasVideoController && player.videoController!.value.isInitialized;
    final isQueueSelected = _tabIndex == 1; // 1 = Queue

    // Show video player ONLY when: video initialized + Details tab + not fullscreen
    if (isVideoInitialized && !isFullscreen && !isQueueSelected) {
      return AspectRatio(
        aspectRatio: player.videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(player.videoController!),

            // Play/Pause Overlay
            _buildVideoControls(player),

            // Fullscreen Button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _toggleFullscreen(player),
                tooltip: 'Full screen',
              ),
            ),
          ],
        ),
      );
    }

    // Show placeholder when Queue tab is open (video is in player bar)
    if (isVideoInitialized && isQueueSelected && !isFullscreen) {
      return AspectRatio(
        aspectRatio: player.videoController!.value.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black54,
            image:
                (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(media.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: const Center(
            child: Text(
              'Video playing below',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      );
    }

    // Show loading indicator when video is being initialized
    if (hasVideoController && !isVideoInitialized && !isFullscreen) {
      return AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio while loading
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
            image:
                (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(media.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    // Artwork (shown when audio or when fullscreen is active)
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[900],
          image: (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty)
              ? DecorationImage(
                  image: NetworkImage(media.thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        // Show "Video playing in fullscreen" indicator when in fullscreen
        child: isFullscreen && media.isVideo
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white54, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Playing in fullscreen',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildQueueView(PlayerProvider player, bool isDark) {
    if (player.queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: TextStyle(
            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: player.queue.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = player.queue[index];
        final isCurrent = index == player.currentIndex;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image:
                  (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(item.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            child: isCurrent
                ? const Icon(Icons.equalizer, color: AppColors.primary)
                : null,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isCurrent
                  ? AppColors.primary
                  : (isDark ? Colors.white : AppColors.lightTextPrimary),
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.artistName,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
          ),
          trailing: IconButton(
            tooltip: 'Remove from queue',
            onPressed: () => player.removeFromQueueAt(index),
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              size: 20,
            ),
            splashRadius: 18,
          ),
          onTap: () {
            player.playQueueIndex(index);
          },
        );
      },
    );
  }

  Widget _buildSwitchButton(
    PlayerProvider player,
    MediaItem media,
    bool isDark,
  ) {
    final isVideo = media.isVideo;
    final linked = media.linkedMedia!;

    return GestureDetector(
      onTap: () {
        // ... switch logic ...
        final newItem = MediaItem(
          id: linked.id,
          title: linked.title,
          mediaType: linked.mediaType,
          thumbnailUrl: linked.thumbnailUrl ?? media.thumbnailUrl,
          hlsUrl: linked.hlsUrl,
          status: MediaStatus.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          artist: linked.artist != null
              ? ArtistInfo(id: linked.artist!.id, name: linked.artist!.name)
              : null,
          linkedMedia: LinkedMediaInfo(
            id: media.id,
            title: media.title,
            mediaType: media.mediaType,
            thumbnailUrl: media.thumbnailUrl,
            hlsUrl: media.hlsUrl,
            artist: media.artist != null
                ? ArtistInfo(id: media.artist!.id, name: media.artist!.name)
                : null,
          ),
        );

        final currentPosition = player.position;
        player.play(newItem, startPosition: currentPosition);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF282828)
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isVideo ? 'Switch to audio' : 'Switch to video',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121212)
                    : AppColors.lightSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo ? Icons.music_note_rounded : Icons.videocam_rounded,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSection(MediaItem media, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the artist',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Artist info placeholder
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                backgroundImage:
                    (media.artist?.imageUrl != null &&
                        media.artist!.imageUrl!.isNotEmpty)
                    ? NetworkImage(media.artist!.imageUrl!)
                    : null,
                child:
                    (media.artist?.imageUrl == null ||
                        media.artist!.imageUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white : Colors.grey[600],
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (media.artistId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistDetailScreen(
                              artist: Artist(
                                id: media.artistId!,
                                name: media.artistName,
                                imageUrl: media.artist?.imageUrl,
                                followerCount: media.artist?.followerCount ?? 0,
                                totalPlays: media.playedCount,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.artistName,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatCount(media.artist?.followerCount ?? 0)} Followers',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (media.artistId != null)
                Consumer<ArtistService>(
                  builder: (context, artistService, _) {
                    final library = context.watch<LibraryService>();
                    final isFollowing = library.artists.any(
                      (a) => a.id == media.artistId,
                    );

                    return OutlinedButton(
                      onPressed: () async {
                        await artistService.toggleFollow(media.artistId!);
                        await context.read<LibraryService>().getArtists();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        backgroundColor: isFollowing
                            ? Colors.transparent
                            : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05)),
                        side: BorderSide(
                          color: isFollowing
                              ? (isDark ? Colors.white38 : Colors.black26)
                              : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                      ),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(PlayerProvider player) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: player.togglePlayPause,
        child: Container(
          color: Colors.transparent, // Capture taps
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: !player.isPlaying ? 1.0 : 0.0, // Always show when paused
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFullscreen(PlayerProvider player) {
    if (player.videoController == null) return;
    WebVideoFullscreen.show(context, player.videoController!);
  }

  /// Credits section - Spotify style
  Widget _buildCreditsSection(MediaItem media, bool isDark) {
    final List<Widget> creditWidgets = [];

    void addCredit(String label, String? name) {
      if (name != null && name.isNotEmpty) {
        creditWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$label: $name',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.9)
                    : AppColors.lightTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }

    addCredit('Lyricist', media.lyricist?.name ?? media.lyricistName);
    addCredit('Composer', media.composer?.name ?? media.composerName);
    addCredit('Producer', media.producer?.name ?? media.producerName);
    addCredit('Director', media.director?.name ?? media.directorName);

    if (creditWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: creditWidgets,
    );
  }
}
