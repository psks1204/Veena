import 'package:flutter/material.dart';
import '../../core/models/media_item.dart';
import '../utils/share_media.dart';

/// Share Song Button
///
/// Tapping opens the native share sheet with a deep link URL for the song:
/// https://veenamusiconline.com/song/{songId}
///
/// If the recipient has the app installed, the link opens the song directly.
/// Otherwise, it falls back to the web version of the song page.
///
/// When the platform has no share sheet, [shareMedia] copies the link instead
/// rather than leaving the tap with no visible effect.
class ShareSongButton extends StatelessWidget {
  final MediaItem media;
  final Color? color;
  final double size;

  /// Tight layout for rows that lay their icons out by hand. Defaults to the
  /// standard IconButton hit box, which is the right one nearly everywhere.
  final bool dense;

  const ShareSongButton({
    super.key,
    required this.media,
    this.color,
    this.size = 22,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      // Own context so the iPad popover anchors to this button, not the page.
      builder: (buttonContext) => IconButton(
        tooltip: 'Share song',
        icon: Icon(
          Icons.share_rounded,
          color: color ?? Colors.white70,
          size: size,
        ),
        padding: dense ? EdgeInsets.zero : null,
        constraints: dense ? const BoxConstraints() : null,
        onPressed: () => shareMedia(buttonContext, media),
      ),
    );
  }
}
