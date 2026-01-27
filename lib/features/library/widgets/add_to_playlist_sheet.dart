import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/library_service.dart';
import '../../../core/models/media_item.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final MediaItem mediaItem;

  const AddToPlaylistSheet({super.key, required this.mediaItem});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Refresh playlists to ensure we have the latest list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryService>().getPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.only(top: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add to Playlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                _showCreatePlaylistDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<LibraryService>(
              builder: (context, library, _) {
                 if (library.playlists.isEmpty) {
                   return const Center(child: Text('No playlists yet'));
                 }
                 
                 return ListView.builder(
                   itemCount: library.playlists.length,
                   itemBuilder: (context, index) {
                     final playlist = library.playlists[index];
                     return ListTile(
                       leading: Container(
                         width: 48,
                         height: 48,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(4),
                           color: Colors.grey[800],
                           image: playlist.coverUrl != null
                               ? DecorationImage(
                                   image: NetworkImage(playlist.coverUrl!),
                                   fit: BoxFit.cover,
                                 )
                               : null,
                         ),
                         child: playlist.coverUrl == null
                             ? const Icon(Icons.music_note, color: Colors.white54)
                             : null,
                       ),
                       title: Text(playlist.name),
                       subtitle: Text('${playlist.trackCount} songs'),
                       onTap: () => _addToPlaylist(playlist.id, playlist.name),
                     );
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
             hintText: 'Playlist Name',
             filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
             onPressed: () async {
                if (nameController.text.isNotEmpty) {
                   Navigator.pop(context); // Close dialog
                   final newPlaylist = await context.read<LibraryService>().createPlaylist(nameController.text);
                   if (newPlaylist != null && mounted) {
                      _addToPlaylist(newPlaylist.id, newPlaylist.name);
                   }
                }
             },
             child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToPlaylist(String playlistId, String playlistName) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    final success = await context.read<LibraryService>().addToPlaylist(playlistId, widget.mediaItem.id);
    
    if (mounted) {
       Navigator.pop(context); // Close sheet
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(success ? 'Added to $playlistName' : 'Failed to add to playlist'),
           duration: const Duration(seconds: 2),
         ),
       );
    }
  }
}
