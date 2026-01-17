import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Track List Tile Widget
/// 
/// Reusable list item for tracks with artwork, title, and controls.
class TrackListTile extends StatelessWidget {
  const TrackListTile({
    super.key,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.duration,
    this.trackNumber,
    this.isPlaying = false,
    this.isExplicit = false,
    this.onTap,
    this.onMoreTap,
  });

  final String title;
  final String artist;
  final String? artworkUrl;
  final Duration? duration;
  final int? trackNumber;
  final bool isPlaying;
  final bool isExplicit;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Track number or artwork
            if (trackNumber != null)
              SizedBox(
                width: 32,
                child: Text(
                  trackNumber.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPlaying 
                        ? colorScheme.primary 
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (artworkUrl != null)
              Container(
                width: AppSpacing.artworkSm,
                height: AppSpacing.artworkSm,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                clipBehavior: Clip.antiAlias,
                child: artworkUrl!.isNotEmpty
                    ? Image.network(
                        artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    : _buildPlaceholder(theme),
              ),

            const SizedBox(width: AppSpacing.sm),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isPlaying ? colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isExplicit) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'E',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          artist,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Duration
            if (duration != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatDuration(duration!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],

            // More button
            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
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
        size: 24,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}
