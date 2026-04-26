import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/library_service.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../shared/widgets/media_options_sheet.dart';

/// Simple Section Screen
///
/// Displays a static list of media items without pagination.
/// Used for "See all" of Recently Played, Trending, etc.
class SimpleSectionScreen extends StatelessWidget {
  final String title;
  final List<MediaItem> items;

  const SimpleSectionScreen({
    super.key,
    required this.title,
    required this.items,
  });

  void _playMedia(BuildContext context, List<MediaItem> items, int index) {
    final player = context.read<PlayerProvider>();
    player.playQueue(items, startIndex: index);

    final item = items[index];
    if (item.isVideo) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()));
    }
  }

  void _toggleLike(BuildContext context, MediaItem item) async {
    final mediaService = context.read<MediaService>();
    final libraryService = context.read<LibraryService>();

    await mediaService.toggleLike(item.id, initial: item.liked);

    if (mediaService.isLiked(item.id, initial: item.liked)) {
      libraryService.addFavoriteLocal(item);
    } else {
      libraryService.removeFavoriteLocal(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
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
                  ),
                ),
              ),
            ),
            actions: [
              if (items.isNotEmpty) ...[
                IconButton(
                  onPressed: () {
                    final player = context.read<PlayerProvider>();
                    player.playQueue(items, shuffle: true);
                  },
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: 'Shuffle',
                ),
                IconButton(
                  onPressed: () {
                    final player = context.read<PlayerProvider>();
                    player.playQueue(items);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: 'Play All',
                ),
              ],
            ],
          ),

          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == items.length) {
                    return const SizedBox(height: 140);
                  }

                  final item = items[index];
                  final player = context.watch<PlayerProvider>();
                  final mediaService = context.watch<MediaService>();
                  final isPlaying = player.currentMedia?.id == item.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AuraTrackTile(
                      title: item.title,
                      subtitle: item.artistName,
                      imageUrl: item.thumbnailUrl,
                      isPlaying: isPlaying,
                      isLiked: mediaService.isLiked(
                        item.id,
                        initial: item.liked,
                      ),
                      playedCount: item.playedCount > 0
                          ? item.playedCount
                          : null,
                      likeCount: item.likeCount > 0 ? item.likeCount : null,
                      onTap: () => _playMedia(context, items, index),
                      onLikeTap: () => _toggleLike(context, item),
                      onMoreTap: () {
                        MediaOptionsSheet.show(context, mediaItem: item);
                      },
                    ),
                  );
                }, childCount: items.length + 1),
              ),
            ),
        ],
      ),
    );
  }
}
