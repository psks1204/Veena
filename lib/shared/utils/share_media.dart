import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/media_item.dart';

/// Deep link for a song. Opens the app when installed, the web page otherwise.
String mediaShareUrl(String mediaId) =>
    'https://veenamusiconline.com/song/$mediaId';

String _shareText(String title, String url) =>
    'Listen to "$title" on Veena Music: $url';

/// Share a media item's deep link through the native share sheet.
///
/// Every platform has a way for `Share.share` to fail that the caller cannot
/// see: on the web it throws whenever the browser has no Web Share API (every
/// desktop browser except Safari/Edge) or when the click's user activation has
/// already been consumed, and on iPad it needs an anchor rect or the popover
/// has nowhere to attach. Left uncaught inside an async `onPressed`, all of
/// those look identical to the user — the button does nothing at all.
///
/// So the failures are handled here instead: the link goes to the clipboard and
/// the user is told, which is what they wanted from the share sheet anyway.
///
/// [context] must belong to the widget that was tapped — its render box is what
/// anchors the iPad popover.
Future<void> shareMedia(BuildContext context, MediaItem media) {
  return shareMediaLink(
    context,
    title: media.title,
    url: mediaShareUrl(media.id),
  );
}

/// Same as [shareMedia] for callers that only hold a title and an id.
Future<void> shareMediaLink(
  BuildContext context, {
  required String title,
  required String url,
  String subject = 'Share Song',
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);

  try {
    await Share.share(
      _shareText(title, url),
      subject: subject,
      sharePositionOrigin: _originRect(context),
    );
  } catch (e) {
    debugPrint('shareMediaLink: native share unavailable ($e) — copying link');

    try {
      await Clipboard.setData(ClipboardData(text: _shareText(title, url)));
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Sharing is not available here — link copied'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (clipboardError) {
      debugPrint('shareMediaLink: clipboard fallback failed: $clipboardError');
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Could not share this song'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

/// The tapped widget's rect in global coordinates.
///
/// iPad anchors the share popover here; passing null there makes the sheet
/// fail to present. Harmless everywhere else.
Rect? _originRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;

  return box.localToGlobal(Offset.zero) & box.size;
}
