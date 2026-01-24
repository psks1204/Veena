import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/library_provider.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/media_item.dart';

/// Shows a bottom sheet to add a song to a playlist
Future<void> showAddToPlaylistSheet(BuildContext context, MediaItem media) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddToPlaylistSheet(media: media),
  );
}

class AddToPlaylistSheet extends StatefulWidget {
  final MediaItem media;

  const AddToPlaylistSheet({super.key, required this.media});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  bool _isLoading = false;
  String? _addingToPlaylistId;

  @override
  void initState() {
    super.initState();
    // Refresh playlists when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadPlaylists();
    });
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    setState(() {
      _isLoading = true;
      _addingToPlaylistId = playlist.id;
    });

    final success = await context.read<LibraryProvider>().addToPlaylist(
      playlist.id,
      widget.media.id,
    );

    setState(() {
      _isLoading = false;
      _addingToPlaylistId = null;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Added "${widget.media.title}" to ${playlist.name}'
                : 'Failed to add to playlist',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext);
                final playlist = await context.read<LibraryProvider>().createPlaylist(
                  nameController.text.trim(),
                );
                if (playlist != null && mounted) {
                  _addToPlaylist(playlist);
                }
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final libraryProvider = context.watch<LibraryProvider>();
    final playlists = libraryProvider.playlists;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Song thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.media.thumbnailUrl != null
                      ? Image.network(
                          widget.media.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                        )
                      : const Icon(Icons.music_note),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Playlist',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.media.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Create new playlist button
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            title: const Text(
              'Create New Playlist',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: _showCreatePlaylistDialog,
          ),

          const Divider(height: 1),

          // Playlists list
          Flexible(
            child: libraryProvider.isLoadingPlaylists
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : playlists.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No playlists yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first playlist above',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final isAdding = _addingToPlaylistId == playlist.id;

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: playlist.coverUrl != null
                                  ? Image.network(
                                      playlist.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.queue_music),
                                    )
                                  : const Icon(Icons.queue_music),
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${playlist.trackCount} tracks'),
                            trailing: isAdding
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_circle_outline),
                            onTap: _isLoading ? null : () => _addToPlaylist(playlist),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
