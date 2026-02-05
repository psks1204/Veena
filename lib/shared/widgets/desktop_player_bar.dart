import 'package:flutter/material.dart';
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
  final bool isQueueTabOpen;  // True when Queue tab is selected in NowPlayingPanel

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
            color: const Color(0xFF181818),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Progress bar (full width at top)
              _buildProgressBar(player),
              
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Left: Track Info
                      Expanded(
                        flex: 3,
                        child: _buildTrackInfo(media, player),
                      ),
                      
                      // Center: Playback Controls
                      Expanded(
                        flex: 4,
                        child: _buildPlaybackControls(player),
                      ),
                      
                      // Right: Volume & Actions
                      Expanded(
                        flex: 3,
                        child: _buildVolumeAndActions(player),
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
  Widget _buildProgressBar(PlayerProvider player) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringProgress = true),
      onExit: (_) => setState(() => _isHoveringProgress = false),
      child: SizedBox(
        height: 6, // Slightly taller container for easier hover
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
                activeTrackColor: _isHoveringProgress ? AppColors.primary : Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: _isHoveringProgress ? Colors.white : Colors.transparent,
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

  /// Left section: Track artwork (or mini video when queue is open), title, artist, like button
  Widget _buildTrackInfo(MediaItem media, PlayerProvider player) {
    // Check if video is playing
    final isVideoPlaying = media.isVideo && 
        player.videoController != null && 
        player.videoController!.value.isInitialized;
    
    // CRITICAL: Only render VideoPlayer when Queue tab is open
    // This ensures only ONE VideoPlayer exists in the widget tree at any time
    final showVideoHere = widget.isQueueTabOpen && isVideoPlaying;

    return Row(
      children: [
        // Container that holds artwork OR video player (never both)
        GestureDetector(
          onTap: widget.onNowPlayingToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
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
                      : const Icon(Icons.music_note_rounded, color: Colors.white54),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                  color: Colors.white.withOpacity(0.7),
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
        _buildLikeButton(media),
      ],
    );
  }

  Widget _buildLikeButton(MediaItem media) {
    return Consumer<LibraryService>(
      builder: (context, library, _) {
        final isLiked = library.favorites.any((item) => item.id == media.id);
        
        return IconButton(
          onPressed: () async {
             final mediaService = context.read<MediaService>();
             await mediaService.toggleLike(media.id);
             if (mounted) {
               context.read<LibraryService>().getFavorites();
             }
          },
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked ? AppColors.primary : Colors.white70,
            size: 20,
          ),
          splashRadius: 20,
          tooltip: isLiked ? 'Remove from Your Library' : 'Save to Your Library',
        );
      },
    );
  }

  /// Center section: Playback controls and time
  Widget _buildPlaybackControls(PlayerProvider player) {
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
                color: player.shuffleEnabled ? AppColors.primary : Colors.white70,
                size: 20,
              ),
              splashRadius: 18,
              tooltip: 'Enable shuffle',
            ),
            const SizedBox(width: 8),
            
            // Previous
            IconButton(
              onPressed: () => player.previous(),
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Next
            IconButton(
              onPressed: () => player.next(),
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
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
                color: player.repeatMode != RepeatMode.off ? AppColors.primary : Colors.white70,
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
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'monospace', 
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(player.duration),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Right section: Volume, queue, now playing toggle
  Widget _buildVolumeAndActions(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Now Playing Panel Toggle
        IconButton(
          onPressed: widget.onNowPlayingToggle,
          icon: Icon(
            Icons.queue_music_rounded, 
            color: widget.isNowPlayingOpen ? AppColors.primary : Colors.white70,
            size: 20,
          ),
          splashRadius: 18,
          tooltip: 'Now Playing View',
        ),
        
        // Volume
        _buildVolumeControl(player),
        
        const SizedBox(width: 8),
      ],
    );
  }

  /// Volume control with slider
  Widget _buildVolumeControl(PlayerProvider player) {
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
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          splashRadius: 18,
          tooltip: player.isMuted ? 'Unmute' : 'Mute',
        ),
        SizedBox(
          width: 90,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: _isDraggingVolume ? Colors.white : Colors.transparent, // Hide thumb when not interacting
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
