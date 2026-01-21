import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Floating Mini Player Widget
/// 
/// Floating capsule-style player showing current track with playback controls.
/// Sits above the bottom navigation bar.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.trackTitle,
    required this.artistName,
    this.artworkUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.onTap,
    this.onPlayPause,
    this.onNext,
    this.onFavorite,
  });

  final String trackTitle;
  final String artistName;
  final String? artworkUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64, // Slightly taller for floating look
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.darkSurfaceVariant.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl), // Rounded capsule
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Stronger shadow for float
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
               // Progress indicator at bottom ( subtle line )
               Positioned(
                 bottom: 0, 
                 left: 12, 
                 right: 12,
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(2),
                   child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 2,
                               ),
                 ),
               ),
              
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.md,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs + 4, // Space for progress bar
                ),
                child: Row(
                  children: [
                    // Artwork
                    Hero(
                      tag: 'mini_player_artwork',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: artworkUrl != null && artworkUrl!.isNotEmpty
                            ? Image.network(
                                artworkUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                              )
                            : _buildPlaceholder(theme),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    
                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trackTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artistName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite - Heart
                        if (onFavorite != null)
                        IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            Icons.favorite_border_rounded, // or favorite_rounded based on state
                            size: 24,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),

                        const SizedBox(width: 4),

                        // Play/Pause - Floating Circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 24,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}
