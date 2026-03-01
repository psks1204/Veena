import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/models/media_item.dart';
import '../../core/services/media_service.dart';
import '../../core/services/library_service.dart';

/// Spotify-style Desktop Player Bar
///
/// Fixed at the bottom of the screen on desktop/web.
/// Three sections: Track Info | Playback Controls | Volume & Actions
class DesktopPlayerBar extends StatefulWidget {
  const DesktopPlayerBar({
    super.key,
    this.onNowPlayingToggle,
    this.isNowPlayingOpen = false,
    this.isQueueTabOpen = false,
  });

  final VoidCallback? onNowPlayingToggle;
  final bool isNowPlayingOpen;
  final bool
  isQueueTabOpen; // True when Queue tab is selected in NowPlayingPanel

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  double _volume = 0.5;
  bool _isMuted = false;
  bool _isHoveringProgress = false;
  bool _isDraggingVolume = false;

  @override
  void initState() {
    super.initState();
    // Initialize volume from player if possible, or default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final player = context.read<PlayerProvider>();
        setState(() {
          _volume = player.volume;
          _isMuted = player.isMuted;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF181818)
        : AppColors.lightSurface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasMedia) {
          return const SizedBox.shrink();
        }

        final media = player.currentMedia!;

        // Sync volume state if changed externally
        if (_volume != player.volume && !_isDraggingVolume) {
          _volume = player.volume;
        }

        return Container(
          height: 90,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            children: [
              // Progress bar (full width at top)
              _buildProgressBar(player, isDark),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Left: Track Info
                      Expanded(
                        flex: 3,
                        child: _buildTrackInfo(media, player, isDark),
                      ),

                      // Center: Playback Controls
                      Expanded(
                        flex: 4,
                        child: _buildPlaybackControls(player, isDark),
                      ),

                      // Right: Volume & Actions
                      Expanded(
                        flex: 3,
                        child: _buildVolumeAndActions(player, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Progress bar spanning full width
  Widget _buildProgressBar(PlayerProvider player, bool isDark) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringProgress = true),
      onExit: (_) => setState(() => _isHoveringProgress = false),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            // Background track
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: 4,
            ),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _isHoveringProgress
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.lightTextPrimary),
                inactiveTrackColor: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                thumbColor: _isHoveringProgress
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : Colors.transparent,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: _isHoveringProgress ? 6 : 0,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                trackHeight: 4,
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: player.progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  player.seekToProgress(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left section
  Widget _buildTrackInfo(MediaItem media, PlayerProvider player, bool isDark) {
    final isVideoPlaying =
        media.isVideo &&
        player.videoController != null &&
        player.videoController!.value.isInitialized;

    final showVideoHere = widget.isQueueTabOpen && isVideoPlaying;

    return Row(
      children: [
        // Container that holds artwork OR video player
        GestureDetector(
          onTap: widget.onNowPlayingToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              clipBehavior: Clip.antiAlias,
              child: showVideoHere
                  // Show VideoPlayer ONLY when Queue tab is open
                  ? AspectRatio(
                      aspectRatio: player.videoController!.value.aspectRatio,
                      child: VideoPlayer(player.videoController!),
                    )
                  // Show artwork when Details tab or when audio
                  : media.thumbnailUrl != null
                  ? Image.network(media.thumbnailUrl!, fit: BoxFit.cover)
                  : Icon(
                      Icons.music_note_rounded,
                      color: isDark ? Colors.white54 : Colors.black26,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Title & Artist
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onNowPlayingToggle,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    media.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                media.artistName ?? 'Unknown Artist',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Like button
        _buildLikeButton(media, isDark),
      ],
    );
  }

  Widget _buildLikeButton(MediaItem media, bool isDark) {
    return Consumer2<LibraryService, MediaService>(
      builder: (context, library, mediaService, _) {
        final isLiked = mediaService.isLiked(media.id, initial: media.liked);

        return IconButton(
          onPressed: () async {
            final libraryService = context.read<LibraryService>();

            await mediaService.toggleLike(media.id, initial: media.liked);

            // Update local state for immediate UI reflection
            if (mediaService.isLiked(media.id, initial: media.liked)) {
              libraryService.addFavoriteLocal(media);
            } else {
              libraryService.removeFavoriteLocal(media.id);
            }

            if (mounted) {
              context.read<LibraryService>().getFavorites();
            }
          },
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
            size: 20,
          ),
          splashRadius: 20,
          tooltip: isLiked
              ? 'Remove from Your Library'
              : 'Save to Your Library',
        );
      },
    );
  }

  /// Center section
  Widget _buildPlaybackControls(PlayerProvider player, bool isDark) {
    final iconColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final secondaryIconColor = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              onPressed: () => player.toggleShuffle(),
              icon: Icon(
                Icons.shuffle_rounded,
                color: player.shuffleEnabled
                    ? AppColors.primary
                    : secondaryIconColor,
                size: 20,
              ),
              splashRadius: 18,
              tooltip: 'Enable shuffle',
            ),
            const SizedBox(width: 8),

            // Previous
            IconButton(
              onPressed: () => player.previous(),
              icon: Icon(
                Icons.skip_previous_rounded,
                color: iconColor,
                size: 28,
              ),
              splashRadius: 20,
              tooltip: 'Previous',
            ),
            const SizedBox(width: 4),

            // Play/Pause
            GestureDetector(
              onTap: () => player.togglePlayPause(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    player.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: isDark ? Colors.black : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Next
            IconButton(
              onPressed: () => player.next(),
              icon: Icon(Icons.skip_next_rounded, color: iconColor, size: 28),
              splashRadius: 20,
              tooltip: 'Next',
            ),
            const SizedBox(width: 8),

            // Repeat
            IconButton(
              onPressed: () => player.toggleRepeatMode(),
              icon: Icon(
                player.repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: player.repeatMode != RepeatMode.off
                    ? AppColors.primary
                    : secondaryIconColor,
                size: 20,
              ),
              splashRadius: 18,
              tooltip: 'Enable repeat',
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Time display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(player.position),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(player.duration),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Right section
  Widget _buildVolumeAndActions(PlayerProvider player, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Now Playing Panel Toggle
        IconButton(
          onPressed: widget.onNowPlayingToggle,
          icon: Icon(
            Icons.queue_music_rounded,
            color: widget.isNowPlayingOpen
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
            size: 20,
          ),
          splashRadius: 18,
          tooltip: 'Now Playing View',
        ),

        // Volume
        _buildVolumeControl(player, isDark),

        const SizedBox(width: 8),
      ],
    );
  }

  /// Volume control with slider
  Widget _buildVolumeControl(PlayerProvider player, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            player.toggleMute();
          },
          icon: Icon(
            player.isMuted || player.volume == 0
                ? Icons.volume_off_rounded
                : player.volume < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded,
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.lightTextSecondary,
            size: 20,
          ),
          splashRadius: 18,
          tooltip: player.isMuted ? 'Unmute' : 'Mute',
        ),
        SizedBox(
          width: 90,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDark
                  ? Colors.white
                  : AppColors.lightTextPrimary,
              inactiveTrackColor: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              thumbColor: _isDraggingVolume
                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                  : Colors.transparent, // Hide thumb when not interacting
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 4,
            ),
            child: Listener(
              onPointerDown: (_) => setState(() => _isDraggingVolume = true),
              onPointerUp: (_) => setState(() => _isDraggingVolume = false),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isDraggingVolume = true),
                onExit: (_) => setState(() => _isDraggingVolume = false),
                child: Slider(
                  value: player.isMuted ? 0 : player.volume,
                  onChanged: (v) {
                    player.setVolume(v);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
