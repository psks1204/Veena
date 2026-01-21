import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Full Screen Player Widget
/// 
/// Expandable full-screen player with artwork, controls, and lyrics area.
/// Uses DraggableScrollableSheet for smooth expansion.
class FullPlayer extends StatelessWidget {
  const FullPlayer({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumName,
    this.artworkUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.duration = const Duration(minutes: 3, seconds: 30),
    this.currentPosition = Duration.zero,
    this.isShuffleOn = false,
    this.repeatMode = RepeatMode.off,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.onSeek,
    this.onClose,
  });

  final String trackTitle;
  final String artistName;
  final String albumName;
  final String? artworkUrl;
  final bool isPlaying;
  final double progress;
  final Duration duration;
  final Duration currentPosition;
  final bool isShuffleOn;
  final RepeatMode repeatMode;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    // Cap artwork size for web/desktop to prevent overflow
    final artworkSize = screenSize.width > 500 
        ? 400.0 
        : screenSize.width - (AppSpacing.xl * 2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF2A2A2A),
                  AppColors.darkBg,
                ]
              : [
                  const Color(0xFFE8E8E8),
                  AppColors.lightBg,
                ],
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
                    onPressed: onClose,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'PLAYING FROM PLAYLIST',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          albumName,
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

            // Artwork
            Container(
              width: artworkSize,
              height: artworkSize,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
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
              child: artworkUrl != null && artworkUrl!.isNotEmpty
                  ? Image.network(
                      artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(theme, artworkSize),
                    )
                  : _buildPlaceholder(theme, artworkSize),
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
                          trackTitle,
                          style: theme.textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          artistName,
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
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border_rounded),
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
                      value: progress.clamp(0.0, 1.0),
                      onChanged: onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
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
                  // Shuffle
                  IconButton(
                    onPressed: onShuffle,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffleOn 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  // Previous
                  IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.skip_previous_rounded, size: 40),
                  ),
                  
                  // Play/Pause
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onPlayPause,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isPlaying 
                              ? Icons.pause_rounded 
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          size: 40,
                          color: colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                  
                  // Next
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next_rounded, size: 40),
                  ),
                  
                  // Repeat
                  IconButton(
                    onPressed: onRepeat,
                    icon: Icon(
                      repeatMode == RepeatMode.one 
                          ? Icons.repeat_one_rounded 
                          : Icons.repeat_rounded,
                      color: repeatMode != RepeatMode.off 
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
                    icon: Icon(
                      Icons.devices_rounded,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.queue_music_rounded,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
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
}

enum RepeatMode { off, all, one }
