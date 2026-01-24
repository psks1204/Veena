import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Aura Album Card - Vertical
/// Square image with gradient overlay.
class AuraAlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;
  final bool isNew;

  const AuraAlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded( // Assuming usage in a Grid or constrained height container, otherwise AspectRatio
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                   Container(
                     decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.1),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           )
                        ],
                     ),
                     clipBehavior: Clip.antiAlias,
                     child: CachedNetworkImage(
                       imageUrl: imageUrl,
                       fit: BoxFit.cover,
                       placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainerHighest),
                       errorWidget: (context, url, error) => const Icon(Icons.error),
                     ),
                   ),
                   // Gradient Overlay
                   Container(
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.transparent,
                           Colors.black.withOpacity(0.3),
                         ],
                       ),
                     ),
                   ),
                   if (isNew)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final String? imageUrl;
  final int? index;

  const AuraTrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.duration,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.imageUrl,
    this.index,
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
          border: isPlaying ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
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
                     CachedNetworkImage(
                       imageUrl: imageUrl!,
                       fit: BoxFit.cover,
                     ),
                     if (isPlaying)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Icon(Icons.graphic_eq, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ] else if (index != null) ...[
               SizedBox(
                 width: 32,
                 child: isPlaying 
                    ? const Icon(Icons.graphic_eq, color: AppColors.primary, size: 20)
                    : Text(
                         '$index',
                         textAlign: TextAlign.center,
                         style: theme.textTheme.bodyMedium?.copyWith(
                           color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (duration != null)
              Text(
                duration!,
                style: theme.textTheme.bodySmall?.copyWith(
                   color: isPlaying ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                   fontWeight: FontWeight.w500,
                ),
              ),
              
            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                Icons.more_vert, 
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
