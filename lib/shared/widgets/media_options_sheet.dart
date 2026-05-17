import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/media_item.dart';
import '../../core/models/media_download_models.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/app_settings_service.dart';
import '../../features/library/widgets/add_to_playlist_sheet.dart';
import '../../features/player/widgets/comments_sheet.dart';
import 'subscription_modal.dart';

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
    final appSettings = context.watch<AppSettingsService>();
    final commentsEnabled = appSettings.enableComments;
    final allowUserDownloads = appSettings.allowUserDownloads;
    final downloadProvider = context.watch<DownloadProvider>();
    final subscription = context.watch<SubscriptionProvider>();

    final supportsDownloads = downloadProvider.isPlatformSupported;
    final isSubscribed = subscription.isNoAdsSubscribed;
    final canShowDownloadAction =
        supportsDownloads && (allowUserDownloads || isSubscribed);
    final isDownloaded = downloadProvider.isDownloaded(mediaItem.id);
    final isDownloading = downloadProvider.isDownloading(mediaItem.id);

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
            if (canShowDownloadAction)
              ListTile(
                leading: isDownloaded
                    ? const Icon(
                        Icons.download_done_rounded,
                        color: Colors.green,
                      )
                    : isDownloading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isSubscribed
                            ? Icons.download_rounded
                            : Icons.lock_rounded,
                      ),
                title: Text(
                  isDownloaded
                      ? 'Downloaded'
                      : isDownloading
                      ? 'Downloading...'
                      : isSubscribed
                      ? 'Download'
                      : 'Download (Premium)',
                ),
                onTap: (isDownloaded || isDownloading)
                    ? null
                    : () {
                        Navigator.pop(context);
                        Future.microtask(() async {
                          if (!context.mounted) return;

                          final subscriptionProvider = context
                              .read<SubscriptionProvider>();
                          if (!subscriptionProvider.isNoAdsSubscribed) {
                            await subscriptionProvider.refreshStatus();
                            if (!context.mounted) return;
                          }

                          if (!subscriptionProvider.isNoAdsSubscribed) {
                            await showSubscriptionModal(context);
                            return;
                          }

                          final result = await context
                              .read<DownloadProvider>()
                              .downloadMedia(mediaItem);
                          if (!context.mounted) return;

                          final messenger = ScaffoldMessenger.of(context);
                          switch (result.status) {
                            case MediaDownloadStatus.success:
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Downloaded for offline playback',
                                  ),
                                ),
                              );
                              break;
                            case MediaDownloadStatus.alreadyDownloaded:
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Media already downloaded'),
                                ),
                              );
                              break;
                            case MediaDownloadStatus.inProgress:
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Download already in progress'),
                                ),
                              );
                              break;
                            case MediaDownloadStatus.notSubscribed:
                              await showSubscriptionModal(context);
                              break;
                            case MediaDownloadStatus.unsupportedPlatform:
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Downloads are available on Android and iOS only',
                                  ),
                                ),
                              );
                              break;
                            case MediaDownloadStatus.failed:
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.message ??
                                        'Failed to download media',
                                  ),
                                ),
                              );
                              break;
                          }
                        });
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
