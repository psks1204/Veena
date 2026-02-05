import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/models/media_item.dart';
import '../../core/utils/fullscreen_web.dart' if (dart.library.io) '../../core/utils/fullscreen_stub.dart' as fullscreen;
import 'web_video_fullscreen.dart';
import 'lyrics_card.dart';

/// Spotify-style Now Playing Panel
/// 
/// Right-side panel showing current track artwork, info, queue, and inline video.
class NowPlayingPanel extends StatefulWidget {
  const NowPlayingPanel({
    super.key,
    this.onClose,
    this.onTabChanged,
  });

  final VoidCallback? onClose;
  final ValueChanged<bool>? onTabChanged;  // Called with true when Queue tab opens

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

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasMedia) {
          return _buildEmptyState();
        }

        final media = player.currentMedia!;

        return Container(
          width: 340,
          color: const Color(0xFF121212),
          child: Column(
            children: [
              // Header
              _buildHeader(media),
              
              // Tabs (Details / Queue)
              _buildTabs(),

              // Content
              Expanded(
                child: _tabIndex == 0 
                    ? _buildDetailsView(player, media) 
                    : _buildQueueView(player),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 340,
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, color: Colors.white.withOpacity(0.2), size: 64),
            const SizedBox(height: 16),
            Text(
              'Play something to see it here',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MediaItem media) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            media.album?.name ?? media.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
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
                widget.onTabChanged?.call(false);  // Notify parent: Details opened
                
                // Auto-resume video after tab switch (Flutter Web workaround)
                // Brief delay allows VideoPlayer to mount in NowPlayingPanel
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
                  color: _tabIndex == 0 ? const Color(0xFF3E3E3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'Details',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                widget.onTabChanged?.call(true);  // Notify parent: Queue opened
                
                // Auto-resume video after tab switch (Flutter Web workaround)
                // Brief delay allows VideoPlayer to mount in DesktopPlayerBar
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
                  color: _tabIndex == 1 ? const Color(0xFF3E3E3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'Queue',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView(PlayerProvider player, MediaItem media) {
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
            _buildSwitchButton(player, media),

          if (media.linkedMedia != null)
            const SizedBox(height: 16),
          
          // Lyrics Card (before track info)
          if (player.currentLyrics != null)
            LyricsCard(
              lyrics: player.currentLyrics!,
              activeIndex: player.activeLyricIndex,
            ),
          
          if (player.currentLyrics != null)
            const SizedBox(height: 20),

          // Track Info
          Text(
            media.title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            media.artistName ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          
          const SizedBox(height: 24),

          // Artist Section
          _buildArtistSection(media),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMediaContent(PlayerProvider player, MediaItem media) {
    // IMPORTANT: Only ONE VideoPlayer should exist in the entire widget tree at any time
    // On Flutter Web, multiple VideoPlayers with same controller cause DOM conflicts
    final isFullscreen = WebVideoFullscreen.isFullscreenActive;
    final hasVideoController = media.isVideo && player.videoController != null;
    final isVideoInitialized = hasVideoController && player.videoController!.value.isInitialized;
    final isQueueSelected = _tabIndex == 1;
    
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
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
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
            image: media.thumbnailUrl != null
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
        aspectRatio: 16 / 9,  // Default aspect ratio while loading
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
            image: media.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(media.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
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
          image: media.thumbnailUrl != null
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

  Widget _buildQueueView(PlayerProvider player) {
    if (player.queue.isEmpty) {
      return const Center(
        child: Text('Queue is empty', style: TextStyle(color: Colors.white54)),
      );
    }
    
    return ListView.builder(
      itemCount: player.queue.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = player.queue[index];
        final isCurrent = index == player.playQueueIndex;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: item.thumbnailUrl != null
                  ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                  : null,
              color: Colors.grey[800],
            ),
            child: isCurrent ? const Icon(Icons.equalizer, color: AppColors.primary) : null,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isCurrent ? AppColors.primary : Colors.white,
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.artistName ?? 'Unknown',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            maxLines: 1,
          ),
          onTap: () {
            player.playQueueIndex(index);
          },
        );
      },
    );
  }

  Widget _buildSwitchButton(PlayerProvider player, MediaItem media) {
    final isVideo = media.isVideo;
    final linked = media.linkedMedia!;
    
    return GestureDetector(
      onTap: () {
        // Create MediaItem from linked media
        final newItem = MediaItem(
          id: linked.id,
          title: linked.title,
          mediaType: linked.mediaType,
          thumbnailUrl: linked.thumbnailUrl ?? media.thumbnailUrl,
          hlsUrl: linked.hlsUrl,
          status: MediaStatus.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          artist: linked.artist != null ? ArtistInfo(
            id: linked.artist!.id,
            name: linked.artist!.name,
          ) : null,
          linkedMedia: LinkedMediaInfo(
            id: media.id,
            title: media.title,
            mediaType: media.mediaType,
            thumbnailUrl: media.thumbnailUrl,
            hlsUrl: media.hlsUrl,
            artist: media.artist != null ? ArtistInfo(
              id: media.artist!.id,
              name: media.artist!.name,
            ) : null,
          ),
        );

        // Capture current position and log it
        final currentPosition = player.position;
        debugPrint('[SwitchButton] Current position: ${currentPosition.inSeconds}s');
        debugPrint('[SwitchButton] Switching from ${media.isVideo ? "video" : "audio"} to ${linked.mediaType}');
        
        // Switch media while preserving position
        player.play(newItem, startPosition: currentPosition);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isVideo ? 'Switch to audio' : 'Switch to video',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo ? Icons.music_note_rounded : Icons.videocam_rounded, 
                color: Colors.white, 
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSection(MediaItem media) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the artist',
            style: TextStyle(
              color: Colors.white,
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
                backgroundColor: Colors.grey[800],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.artistName ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      '1.2M listeners',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Follow'),
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
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
}
