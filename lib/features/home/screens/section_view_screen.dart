import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/video_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';

/// Section View Screen
/// 
/// Displays a grid of media items for a specific section (e.g. Latest Releases, Popular).
/// Used when clicking "See All" on the Home Screen.
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No items found',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AuraAlbumCard(
                  title: item.title,
                  subtitle: item.artistName,
                  imageUrl: item.thumbnailUrl ?? '',
                  mediaType: item.mediaType,
                  onTap: () => _playMedia(context, item),
                  onMoreTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddToPlaylistSheet(mediaItem: item),
                    );
                  },
                );
              },
            ),
    );
  }

  void _playMedia(BuildContext context, MediaItem item) {
    final player = context.read<PlayerProvider>();
    player.play(item);

    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VideoPlayerScreen()),
      );
    }
  }
}
