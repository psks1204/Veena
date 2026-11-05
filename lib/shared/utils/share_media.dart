import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/media_item.dart';

/// Deep link for a song. Opens the app when installed, the web page otherwise.
String mediaShareUrl(String mediaId) =>
    'https://veenamusiconline.com/song/$mediaId';

/// Deep link for a reel. Opens the app when installed, the web page otherwise.
String reelShareUrl(String mediaId) =>
    'https://veenamusiconline.com/reel/$mediaId';

String _shareText(String title, String url, {bool isReel = false}) =>
    isReel
        ? 'Watch "$title" on Veena: $url'
        : 'Listen to "$title" on Veena Music: $url';

/// Share a media item's deep link through the native share sheet.
/// If [media.isChannelMedia] is true, generates a reel share link.
Future<void> shareMedia(BuildContext context, MediaItem media) {
  final isReel = media.isChannelMedia;
  return shareMediaLink(
    context,
    title: media.title,
    url: isReel ? reelShareUrl(media.id) : mediaShareUrl(media.id),
    subject: isReel ? 'Share Reel' : 'Share Song',
    isReel: isReel,
  );
}

/// Same as [shareMedia] for callers that only hold a title and an id.
Future<void> shareMediaLink(
  BuildContext context, {
  required String title,
  required String url,
  String subject = 'Share Song',
  bool isReel = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);

  try {
    await Share.share(
      _shareText(title, url, isReel: isReel),
      subject: subject,
      sharePositionOrigin: _originRect(context),
    );
  } catch (e) {
    debugPrint('shareMediaLink: native share unavailable ($e) — copying link');

    try {
      await Clipboard.setData(
        ClipboardData(text: _shareText(title, url, isReel: isReel)),
      );
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Sharing is not available here — link copied'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (clipboardError) {
      debugPrint('shareMediaLink: clipboard fallback failed: $clipboardError');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isReel ? 'Could not share this reel' : 'Could not share this song',
          ),
        ),
      );
    }
  }
}

/// The tapped widget's rect in global coordinates.
Rect? _originRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;

  return box.localToGlobal(Offset.zero) & box.size;
}
