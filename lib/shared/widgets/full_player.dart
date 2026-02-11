import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/models/lyrics_model.dart';
import '../widgets/lyrics_card.dart';
import '../../features/library/widgets/add_to_playlist_sheet.dart';
import '../../features/library/screens/album_detail_screen.dart';
import 'seekbar_control.dart';


/// Full Screen Player Widget - Redesigned for Spotify aesthetics
/// Responsive: Mobile stays the same, Web/Tablet gets a constrained centered layout
class FullPlayer extends StatelessWidget {
  const FullPlayer({
    super.key,
    required this.mediaItem,
    this.isPlaying = false,
    this.progress = 0.0,
    this.duration = const Duration(minutes: 3, seconds: 30),
    this.currentPosition = Duration.zero,
    this.isShuffleOn = false,
    this.repeatMode = RepeatMode.off,
    this.lyrics,
    this.activeLyricIndex = -1,
    this.onFullscreenLyricsTap,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.onSeek,
    this.onClose,
  });

  final MediaItem mediaItem;
  final bool isPlaying;
  final double progress;
  final Duration duration;
  final Duration currentPosition;
  final bool isShuffleOn;
  final RepeatMode repeatMode;
  final Lyrics? lyrics;
  final int activeLyricIndex;
  final VoidCallback? onFullscreenLyricsTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onClose;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _navigateToAlbum(BuildContext context) {
    if (mediaItem.album != null) {
      // Close player first if it's a modal or separate screen
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Navigate to album detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumDetailScreen(albumId: mediaItem.album!.id.toString()),
        ),
      );
    }
  }

  void _showQueueSheet(BuildContext context) {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${player.queue.length} tracks',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Queue list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: player.queue.length,
                  itemBuilder: (context, index) {
                    final track = player.queue[index];
                    final isCurrent = index == player.currentIndex;
                    return ListTile(
                      onTap: () {
                        player.playQueueIndex(index);
                        Navigator.pop(context);
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[800],
                          child: track.thumbnailUrl != null
                              ? Image.network(track.thumbnailUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artistName ?? 'Unknown Artist',
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary.withAlpha(179) : Colors.white54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.equalizer_rounded, color: AppColors.primary)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Web/Tablet detection - only change layout for larger screens
    final isLargeScreen = screenSize.width >= 768;
    
    // For mobile: full width artwork. For web/tablet: compact size
    final artworkSize = isLargeScreen 
        ? 240.0 
        : screenSize.width - (AppSpacing.xl * 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Blurred Background layer
          if (mediaItem.thumbnailUrl != null && mediaItem.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Image.network(
                  mediaItem.thumbnailUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          
          // 2. Main Content layer
          SafeArea(
            child: isLargeScreen 
                ? _buildWebTabletLayout(context, theme, artworkSize)
                : _buildMobileLayout(context, theme, artworkSize),
          ),
        ],
      ),
    );
  }

  /// Web/Tablet Layout - Side by side with constrained max width
  Widget _buildWebTabletLayout(BuildContext context, ThemeData theme, double artworkSize) {
    final hasLyrics = lyrics != null && lyrics!.lines.isNotEmpty;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side - Artwork, Metadata and Controls
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildWebTopBar(context, theme),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Artwork
                                Container(
                                  width: artworkSize,
                                  height: artworkSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 40,
                                        offset: const Offset(0, 20),
                                      ),
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 60,
                                        spreadRadius: -10,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: mediaItem.thumbnailUrl != null && mediaItem.thumbnailUrl!.isNotEmpty
                                      ? Image.network(mediaItem.thumbnailUrl!, fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
                                        ),
                                ),
                                const SizedBox(height: 24),
                                // Track info
                                Column(
                                  children: [
                                    Text(
                                      mediaItem.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mediaItem.fullArtistString,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Credits (Composer/Lyricist) for Web
                                    if (mediaItem.composerName != null || mediaItem.lyricistName != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (mediaItem.composerName != null)
                                            _buildCreditBadge('Music', mediaItem.composerName!),
                                          if (mediaItem.composerName != null && mediaItem.lyricistName != null)
                                            const SizedBox(width: 8),
                                          if (mediaItem.lyricistName != null)
                                            _buildCreditBadge('Lyrics', mediaItem.lyricistName!),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 32),
                                // Web Controls
                                _buildWebControls(context, artworkSize),
                                const SizedBox(height: 20),
                                // Footer icons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(onPressed: () {}, icon: const Icon(Icons.devices_rounded, color: Colors.white54, size: 20)),
                                    const SizedBox(width: 24),
                                    IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: Colors.white54, size: 18)),
                                    const SizedBox(width: 24),
                                    IconButton(onPressed: () => _showQueueSheet(context), icon: const Icon(Icons.list_rounded, color: Colors.white54, size: 22)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side - Lyrics Panel or Empty State
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 40, 40, 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'LYRICS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            if (hasLyrics)
                              IconButton(
                                onPressed: onFullscreenLyricsTap,
                                icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 18),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: hasLyrics 
                          ? _WebLyricsView(
                              lyrics: lyrics!,
                              activeIndex: activeLyricIndex,
                            )
                          : Center(
                              child: Text(
                                'Lyrics not available',
                                style: TextStyle(color: Colors.white24, fontSize: 14),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onClose,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
            ),
          ),
          if (mediaItem.album != null)
            GestureDetector(
              onTap: () => _navigateToAlbum(context),
              child: Column(
                children: [
                  Text(
                    'PLAYING FROM',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mediaItem.albumName?.toUpperCase() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 14),
                    ],
                  ),
                ],
              ),
            )
          else
            const SizedBox(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildWebControls(BuildContext context, double artworkSize) {
    return Container(
      width: artworkSize * 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          // Progress
          SeekbarControl(
            progress: progress,
            duration: duration,
            currentPosition: currentPosition,
            onSeek: onSeek ?? (_) {},
            isWeb: true,
          ),
          const SizedBox(height: 32),
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onShuffle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffleOn ? AppColors.primary : Colors.white38,
                  size: 20,
                ),
                tooltip: 'Shuffle',
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onPrevious,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                tooltip: 'Previous',
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onPlayPause,
                child: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: onNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                tooltip: 'Next',
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onRepeat,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  color: repeatMode != RepeatMode.off ? AppColors.primary : Colors.white38,
                  size: 20,
                ),
                tooltip: 'Repeat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile Layout - Enhanced with Credits and Sub-artists
  Widget _buildMobileLayout(BuildContext context, ThemeData theme, double artworkSize) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Top navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                ),
                if (mediaItem.album != null)
                  GestureDetector(
                    onTap: () => _navigateToAlbum(context),
                    child: Column(
                      children: [
                        Text(
                          'PLAYING FROM',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              mediaItem.albumName!.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  const Text('NOW PLAYING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Artwork section
          Center(
            child: Hero(
              tag: 'player_artwork',
              child: Container(
                width: artworkSize,
                height: artworkSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: mediaItem.thumbnailUrl != null && mediaItem.thumbnailUrl!.isNotEmpty
                    ? Image.network(mediaItem.thumbnailUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Meta info (Title, Artist, Sub-artists)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Artist & Sub-artists
                      Text(
                        mediaItem.fullArtistString,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                     showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddToPlaylistSheet(mediaItem: mediaItem),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          
          // Credits Section (if available)
          if (mediaItem.composerName != null || mediaItem.lyricistName != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (mediaItem.composerName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildCreditBadge('Music', mediaItem.composerName!),
                      ),
                    if (mediaItem.lyricistName != null)
                      _buildCreditBadge('Lyrics', mediaItem.lyricistName!),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: SeekbarControl(
              progress: progress,
              duration: duration,
              currentPosition: currentPosition,
              onSeek: onSeek ?? (_) {},
              isWeb: false,
            ),
          ),

          const SizedBox(height: 12),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: onShuffle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: isShuffleOn ? AppColors.primary : Colors.white60,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: onPrevious,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                ),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                ),
                IconButton(
                  onPressed: onRepeat,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: repeatMode != RepeatMode.off ? AppColors.primary : Colors.white60,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 32),

          // Linked Media Switcher & Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Consumer<PlayerProvider>(
              builder: (context, player, _) {
                final linkedMedia = player.currentMedia?.linkedMedia;
                final hasLinkedVideo = linkedMedia != null && linkedMedia.mediaType == MediaType.video;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Switch to Video button - Spotify style
                    if (hasLinkedVideo)
                      GestureDetector(
                        onTap: () {
                           // Switch logic identical to before, just consolidated
                           final currentPosition = player.position;
                           final videoItem = MediaItem(
                             id: linkedMedia.id,
                             title: linkedMedia.title,
                             mediaType: linkedMedia.mediaType,
                             thumbnailUrl: linkedMedia.thumbnailUrl,
                             hlsUrl: linkedMedia.hlsUrl,
                             status: MediaStatus.published,
                             createdAt: DateTime.now(),
                             updatedAt: DateTime.now(),
                             artist: linkedMedia.artist,
                           );
                           player.play(videoItem, startPosition: currentPosition);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text('Watch Video', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )
                    else 
                      const SizedBox(),
                    
                    const Spacer(),
                    
                    const Icon(Icons.share_outlined, color: Colors.white60, size: 20),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () => _showQueueSheet(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.list_rounded, color: Colors.white60, size: 24),
                    ),
                  ],
                );
              },
            ),
          ),


          const SizedBox(height: 32),

          // Lyrics Section
          if (lyrics != null && lyrics!.lines.isNotEmpty) ...[
            LyricsCard(
              lyrics: lyrics!,
              activeIndex: activeLyricIndex,
              onFullscreenTap: onFullscreenLyricsTap,
            ),
            const SizedBox(height: 60),
          ],

          // "About the artist" section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      if (mediaItem.thumbnailUrl != null)
                        Image.network(
                          mediaItem.thumbnailUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: Text(
                          'About the artist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.fullArtistString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Listening to ${mediaItem.fullArtistString} is a soul-refreshing experience. More bio details would be fetched from API.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Follow'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web Lyrics View - Shows lyrics with auto-scroll for web/tablet
class _WebLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final int activeIndex;

  const _WebLyricsView({
    required this.lyrics,
    required this.activeIndex,
  });

  @override
  State<_WebLyricsView> createState() => _WebLyricsViewState();
}

class _WebLyricsViewState extends State<_WebLyricsView> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 50.0;

  @override
  void didUpdateWidget(_WebLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex && widget.activeIndex >= 0) {
      _scrollToActiveLine();
    }
  }

  void _scrollToActiveLine() {
    if (!_scrollController.hasClients) return;
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.lines.length) return;
    
    final targetOffset = widget.activeIndex * _itemHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      itemCount: widget.lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics.lines[index];
        final isActive = index == widget.activeIndex;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
              fontSize: isActive ? 22 : 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.2,
            ),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
