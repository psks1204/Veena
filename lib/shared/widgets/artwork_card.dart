import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Artwork Card Widget
/// 
/// Reusable card for playlists, albums, and artist artwork.
/// Supports square and rounded variants with consistent styling.
class ArtworkCard extends StatelessWidget {
  const ArtworkCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.size = ArtworkCardSize.medium,
    this.onTap,
    this.isCircular = false,
    this.showPlayButton = false,
  });

  final String imageUrl;
  final String title;
  final String? subtitle;
  final ArtworkCardSize size;
  final VoidCallback? onTap;
  final bool isCircular;
  final bool showPlayButton;

  double get _size {
    switch (size) {
      case ArtworkCardSize.small:
        return 120;
      case ArtworkCardSize.medium:
        return 160;
      case ArtworkCardSize.large:
        return 200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate text area height (title + subtitle + spacing)
    final textAreaHeight = subtitle != null ? 44.0 : 24.0;
    final totalHeight = _size + AppSpacing.sm + textAreaHeight;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _size,
        height: totalHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Artwork
            Stack(
              children: [
                Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      isCircular ? _size / 2 : AppSpacing.radiusLg,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(theme);
                          },
                        )
                      : _buildPlaceholder(theme),
                ),
                
                // Play button overlay
                if (showPlayButton)
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Title
            Text(
              title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Subtitle
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: _size * 0.3,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

enum ArtworkCardSize { small, medium, large }
