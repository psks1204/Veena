import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import 'app_network_image.dart';

/// Aura Album Card - Vertical
/// Square image with gradient overlay and media type badge.
class AuraAlbumCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMoreTap;
  final bool isNew;
  final bool isLiked;
  final MediaType? mediaType;

  const AuraAlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
    this.onLikeTap,
    this.onMoreTap,
    this.isNew = false,
    this.isLiked = false,
    this.mediaType,
  });

  @override
  State<AuraAlbumCard> createState() => _AuraAlbumCardState();
}

class _AuraAlbumCardState extends State<AuraAlbumCard> {
  final ValueNotifier<bool> _hoverNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _hoverNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => _hoverNotifier.value = true,
      onExit: (_) => _hoverNotifier.value = false,
      cursor: SystemMouseCursors.click,
      child: ValueListenableBuilder<bool>(
        valueListenable: _hoverNotifier,
        builder: (context, isHovering, child) {
          return AnimatedScale(
            scale: isHovering ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXl,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isHovering ? 0.2 : 0.1,
                                  ),
                                  blurRadius: isHovering ? 20 : 10,
                                  offset: Offset(0, isHovering ? 8 : 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: widget.imageUrl.isNotEmpty
                                ? AppNetworkImage(
                                    imageUrl: widget.imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 400,
                                    placeholder: Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                    ),
                                    errorChild: _buildPlaceholder(theme),
                                  )
                                : _buildPlaceholder(theme),
                          ),
                          // Gradient Overlay - Always visible or on hover? Keep always for readability
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXl,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  if (isHovering)
                                    Colors.black.withOpacity(0.4)
                                  else
                                    Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          // Play Button Overlay on Hover
                          AnimatedOpacity(
                            opacity: isHovering ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          // Media Type Badge (VIDEO/AUDIO)
                          if (widget.mediaType != null)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white10,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.mediaType == MediaType.video
                                          ? Icons.play_arrow_rounded
                                          : Icons.music_note_rounded,
                                      size: 10,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.mediaType == MediaType.video
                                          ? 'VIDEO'
                                          : 'AUDIO',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 8,
                                            letterSpacing: 0.8,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // NEW Badge
                          if (widget.isNew)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'NEW',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          // Like button
                          if (widget.onLikeTap != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: widget.onLikeTap,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: widget.isLiked
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          // More button
                          if (widget.onMoreTap != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: widget.onMoreTap,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        widget.mediaType == MediaType.video
            ? Icons.videocam_rounded
            : Icons.music_note_rounded,
        size: 40,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

/// Aura Track Tile
class AuraTrackTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? duration;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final bool isLiked;
  final String? imageUrl;
  final int? index;
  final int? playedCount;
  final int? likeCount;

  const AuraTrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.duration,
    this.onTap,
    this.onLikeTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.isLiked = false,
    this.imageUrl,
    this.index,
    this.playedCount,
    this.likeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isPlaying
              ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isPlaying
              ? Border.all(color: AppColors.primary.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            if (imageUrl != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      placeholder: Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorChild: Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Icon(
                          Icons.graphic_eq,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ] else if (index != null) ...[
              SizedBox(
                width: 32,
                child: isPlaying
                    ? const Icon(
                        Icons.graphic_eq,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : Text(
                        '$index',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                      color: isPlaying ? AppColors.primary : null,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((playedCount != null && playedCount! > 0) ||
                      (likeCount != null && likeCount! > 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (playedCount != null && playedCount! > 0) ...[
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 12,
                              color:
                                  (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary)
                                      .withOpacity(0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatPlayCount(playedCount!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (playedCount != null &&
                              playedCount! > 0 &&
                              likeCount != null &&
                              likeCount! > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  color:
                                      (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary)
                                          .withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          if (likeCount != null && likeCount! > 0) ...[
                            Icon(
                              Icons.favorite_rounded,
                              size: 11,
                              color:
                                  (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary)
                                      .withOpacity(0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatPlayCount(likeCount!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (duration != null)
              Text(
                duration!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPlaying
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  fontWeight: FontWeight.w500,
                ),
              ),

            // Like button
            if (onLikeTap != null)
              IconButton(
                onPressed: onLikeTap,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Colors.red
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
              ),

            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                Icons.more_vert,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats play count to readable string (e.g., 1.2K, 3.5M)
  static String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
