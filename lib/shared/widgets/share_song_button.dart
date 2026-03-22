import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/media_item.dart';

/// Share Song Button
///
/// Tapping opens the native share sheet with a deep link URL for the song:
/// https://veenamusiconline.com/song/{songId}
///
/// If the recipient has the app installed, the link opens the song directly.
/// Otherwise, it falls back to the web version of the song page.
class ShareSongButton extends StatelessWidget {
  final MediaItem media;
  final Color? color;
  final double size;

  const ShareSongButton({
    super.key,
    required this.media,
    this.color,
    this.size = 22,
  });

  String get _shareUrl =>
      'https://veenamusiconline.com/song/${media.id}';

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share song',
      icon: Icon(
        Icons.share_rounded,
        color: color ?? Colors.white70,
        size: size,
      ),
      onPressed: () async {
        await Share.share(
          'Listen to "${media.title}" on Veena Music: $_shareUrl',
          subject: 'Share Song',
        );
      },
    );
  }
}
