import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/media_item.dart';
import '../../core/services/app_settings_service.dart';
import '../../features/library/widgets/add_to_playlist_sheet.dart';
import '../../features/player/widgets/comments_sheet.dart';

class MediaOptionsSheet extends StatelessWidget {
  const MediaOptionsSheet({super.key, required this.mediaItem});

  final MediaItem mediaItem;

  static Future<void> show(
    BuildContext context, {
    required MediaItem mediaItem,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaOptionsSheet(mediaItem: mediaItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsEnabled = context.watch<AppSettingsService>().enableComments;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: _thumb(),
              title: Text(
                mediaItem.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                mediaItem.artistName.isEmpty
                    ? 'Unknown Artist'
                    : mediaItem.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() {
                  if (!context.mounted) return;
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AddToPlaylistSheet(mediaItem: mediaItem),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                final shareUrl =
                    'https://veenamusiconline.com/song/${mediaItem.id}';
                await Share.share(
                  'Listen to "${mediaItem.title}" on Veena Music: $shareUrl',
                  subject: 'Share Song',
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.chat_bubble_outline_rounded,
                color: commentsEnabled ? null : Colors.grey,
              ),
              title: Text(
                'Comment',
                style: TextStyle(color: commentsEnabled ? null : Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!commentsEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comments are currently disabled'),
                    ),
                  );
                  return;
                }
                Future.microtask(() {
                  if (!context.mounted) return;
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CommentsSheet(mediaId: mediaItem.id),
                  );
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _thumb() {
    if (mediaItem.thumbnailUrl != null && mediaItem.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          mediaItem.thumbnailUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54),
    );
  }
}
