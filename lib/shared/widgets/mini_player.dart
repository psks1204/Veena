import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Floating Mini Player Widget - Spotify-like Frosted Glass Design
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
    
    // Theme-aware colors
    // Light mode: White background, Dark text
    // Dark mode: Dark background, White text
    final bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtextColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final iconColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final progressBgColor = isDark ? Colors.white12 : Colors.black12;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(isDark ? 0.7 : 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Artwork
                        Hero(
                          tag: 'mini_player_artwork',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              image: artworkUrl != null && artworkUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(artworkUrl!), fit: BoxFit.cover)
                                  : null,
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                            ),
                            child: artworkUrl == null || artworkUrl!.isEmpty
                                ? Icon(Icons.music_note_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 24)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Metadata
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trackTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                artistName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Icons
                        Icon(Icons.devices_rounded, color: iconColor, size: 22),
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onFavorite,
                          icon: Icon(Icons.add_circle_outline_rounded, color: iconColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onPlayPause,
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: iconColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  // Progress bar (Thin line at bottom)
                  Positioned(
                    bottom: 0,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
