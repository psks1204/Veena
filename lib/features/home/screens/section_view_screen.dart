import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';

/// Section View Screen
/// 
/// Displays a list of media items for a specific section (e.g. Latest Releases, Popular).
/// Used when clicking "See All" on the Home Screen.
/// Designed like Spotify with list layout, header with play/shuffle buttons.
class SectionViewScreen extends StatelessWidget {
  final String title;
  final List<MediaItem> items;

  const SectionViewScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(0.6),
                      colorScheme.primary.withOpacity(0.3),
                      isDark ? AppColors.darkBg : AppColors.lightBg,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Action buttons row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Track count
                  Text(
                    '${items.length} ${items.length == 1 ? 'track' : 'tracks'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Shuffle button
                  IconButton(
                    onPressed: items.isNotEmpty ? () => _playAll(context, shuffle: true) : null,
                    icon: const Icon(Icons.shuffle_rounded),
                    tooltip: 'Shuffle',
                  ),
                  
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Play button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: items.isNotEmpty ? colorScheme.primary : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: items.isNotEmpty ? () => _playAll(context) : null,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                      tooltip: 'Play all',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Empty state
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No items found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Track list with nice styling
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final isPlaying = player.currentMedia?.id == item.id;
                    
                    return _TrackListItem(
                      index: index + 1,
                      item: item,
                      isPlaying: isPlaying,
                      onTap: () => _playMedia(context, item, index),
                      onMoreTap: () => _showMoreOptions(context, item),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _playAll(BuildContext context, {bool shuffle = false}) {
    final player = context.read<PlayerProvider>();
    player.playQueue(items, shuffle: shuffle);
  }

  void _playMedia(BuildContext context, MediaItem item, int index) {
    final player = context.read<PlayerProvider>();
    player.playQueue(items, startIndex: index);

    if (item.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  void _showMoreOptions(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistSheet(mediaItem: item),
    );
  }
}

/// Track list item widget with Spotify-like design
class _TrackListItem extends StatelessWidget {
  final int index;
  final MediaItem item;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _TrackListItem({
    required this.index,
    required this.item,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Track number or playing indicator
            SizedBox(
              width: 32,
              child: isPlaying
                  ? Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.primary,
                      size: 18,
                    )
                  : Text(
                      '$index',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
            ),
            
            const SizedBox(width: AppSpacing.sm),
            
            // Artwork thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 48,
                height: 48,
                child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isPlaying 
                          ? AppColors.primary 
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Explicit badge
                      if (item.mediaType == 'VIDEO')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'VIDEO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.artistName ?? 'Unknown Artist',
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
            
            // More button
            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
