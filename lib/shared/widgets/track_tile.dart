import 'package:flutter/material.dart';
import '../../core/models/media_item.dart';
import 'track_list_tile.dart';
import '../../features/library/widgets/add_to_playlist_sheet.dart';

class TrackTile extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback? onMoreTap;
  final VoidCallback? onTap;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.mediaItem,
    this.onTap,
    this.isPlaying = false,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return TrackListTile(
      title: mediaItem.title,
      artist: mediaItem.description ?? 'Unknown Artist',
      artworkUrl: mediaItem.thumbnailUrl,
      isPlaying: isPlaying,
      onTap: onTap,
      onMoreTap: onMoreTap ?? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddToPlaylistSheet(mediaItem: mediaItem),
        );
      },
      // You can parse duration if available in MediaItem, strict parsing required though
    );
  }
}
