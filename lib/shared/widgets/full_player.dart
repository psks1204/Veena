import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/playback_provider.dart';

/// Full Screen Player Widget
/// 
/// Expandable full-screen player with artwork/video, controls, and lyrics area.
class FullPlayer extends StatefulWidget {
  const FullPlayer({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  ChewieController? _chewieController;
  VideoPlayerController? _lastVideoController;
  bool _showLyrics = false;

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  void _initChewie(VideoPlayerController? videoController) {
    if (videoController == null) {
      _chewieController?.dispose();
      _chewieController = null;
      _lastVideoController = null;
      return;
    }
    
    // Only create ChewieController if video is initialized
    if (!videoController.value.isInitialized) {
      return;
    }

    if (_lastVideoController != videoController) {
      _chewieController?.dispose();
      _lastVideoController = videoController;
      _chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: videoController.value.aspectRatio > 0
            ? videoController.value.aspectRatio
            : 16 / 9,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error loading video',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackProvider = context.watch<PlaybackProvider>();
    final media = playbackProvider.currentMedia;
    
    if (media == null) return const SizedBox.shrink();

    if (playbackProvider.currentType == PlaybackType.video) {
       _initChewie(playbackProvider.videoController);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
    final mediaAreaSize = screenSize.width > 500 
        ? 400.0 
        : screenSize.width - (AppSpacing.xl * 2);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF2A2A2A), AppColors.darkBg]
                : [const Color(0xFFE8E8E8), AppColors.lightBg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            media.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Media Area (Artwork or Video)
              Container(
                width: mediaAreaSize,
                height: playbackProvider.currentType == PlaybackType.video 
                    ? mediaAreaSize * (9/16) // Video aspect ratio
                    : mediaAreaSize,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: playbackProvider.currentType == PlaybackType.video && _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : (media.thumbnailUrl != null
                        ? Image.network(
                            media.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(theme, mediaAreaSize),
                          )
                        : _buildPlaceholder(theme, mediaAreaSize)),
              ),

              const Spacer(),

              // Track info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            media.title,
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            media.artistName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => playbackProvider.toggleLike(),
                      icon: Icon(
                        media.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: media.isLiked ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    SliderTheme(
                      data: theme.sliderTheme.copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: playbackProvider.duration.inSeconds > 0
                            ? (playbackProvider.position.inSeconds / playbackProvider.duration.inSeconds).clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (val) {
                          final pos = Duration(seconds: (val * playbackProvider.duration.inSeconds).toInt());
                          playbackProvider.seek(pos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playbackProvider.position),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            _formatDuration(playbackProvider.duration),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => playbackProvider.toggleShuffle(),
                      icon: Icon(
                        Icons.shuffle_rounded, 
                        color: playbackProvider.isShuffleOn 
                            ? colorScheme.primary 
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    IconButton(
                      onPressed: () => playbackProvider.previous(),
                      icon: const Icon(Icons.skip_previous_rounded, size: 40),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => playbackProvider.togglePlay(),
                        icon: Icon(
                          playbackProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 40,
                          color: colorScheme.surface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => playbackProvider.next(),
                      icon: const Icon(Icons.skip_next_rounded, size: 40),
                    ),
                    IconButton(
                      onPressed: () => playbackProvider.cycleRepeatMode(),
                      icon: Icon(
                        playbackProvider.repeatMode == RepeatMode.one 
                            ? Icons.repeat_one_rounded 
                            : Icons.repeat_rounded, 
                        color: playbackProvider.repeatMode != RepeatMode.off 
                            ? colorScheme.primary 
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              
              // Bottom actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.devices_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    // Lyrics button - only show if lyrics are available
                    if (media.lyricsUrl != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                        },
                        icon: Icon(
                          Icons.lyrics_rounded,
                          color: _showLyrics
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.queue_music_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),

              // Lyrics section
              if (_showLyrics && media.lyricsUrl != null)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.md),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _buildLyricsSection(playbackProvider, theme, colorScheme),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlaceholder(ThemeData theme, double size) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.3,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLyricsSection(PlaybackProvider playbackProvider, ThemeData theme, ColorScheme colorScheme) {
    if (playbackProvider.isLoadingLyrics) {
      return const Center(child: CircularProgressIndicator());
    }

    final lyrics = playbackProvider.currentLyrics;
    if (lyrics == null || lyrics.isEmpty) {
      return Center(
        child: Text(
          'Lyrics not available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          lyrics,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
