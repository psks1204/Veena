import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/library_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../player/screens/video_player_screen.dart';
import '../../../shared/layouts/player_overlay_shell.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLoading = true;
  List<MediaItem> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await context.read<LibraryService>().getPlaylistTracks(widget.playlist.id);
      if (mounted) {
        setState(() {
          _tracks = tracks;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlist tracks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Play a track from the playlist - sets up the queue for next/previous
  void _playTrack(MediaItem track, int index) {
    final player = context.read<PlayerProvider>();
    
    // Play the entire playlist as a queue, starting from this track
    if (_tracks.isNotEmpty) {
      debugPrint('[PlaylistDetail] Playing queue: ${_tracks.length} tracks, starting at $index');
      player.playQueue(_tracks, startIndex: index);
    } else {
      player.play(track);
    }
    
    // Open video player if it's a video
    if (track.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const VideoPlayerScreen()),
      );
    }
  }

  /// Play all tracks (or shuffle)
  void _playAll({bool shuffle = false}) {
    if (_tracks.isEmpty) return;
    
    final player = context.read<PlayerProvider>();
    debugPrint('[PlaylistDetail] Play all: ${_tracks.length} tracks, shuffle: $shuffle');
    player.playQueue(_tracks, shuffle: shuffle);
    
    // If first track is video, open video player
    if (_tracks.first.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const VideoPlayerScreen()),
      );
    }
  }

  Future<void> _deletePlaylist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: const Text('Are you sure you want to delete this playlist? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<LibraryService>().deletePlaylist(widget.playlist.id);
      if (success && mounted) {
        Navigator.pop(context); // Go back to library
      }
    }
  }

  void _removeTrack(MediaItem track) async {
    // Optimistic update
    final index = _tracks.indexOf(track);
    setState(() {
      _tracks.remove(track);
    });

    final success = await context.read<LibraryService>().removeFromPlaylist(widget.playlist.id, track.id);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _tracks.insert(index, track);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove track')),
      );
    }
  }

  void _showTrackOptions(MediaItem track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
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
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: track.thumbnailUrl != null
                    ? Image.network(track.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover)
                    : Container(width: 48, height: 48, color: Colors.grey[800], child: const Icon(Icons.music_note)),
              ),
              title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to another playlist'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddToPlaylistSheet(mediaItem: track),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove from this playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeTrack(track);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<PlayerProvider>();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.6),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black45, offset: Offset(0, 10))],
                          image: widget.playlist.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.playlist.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: widget.playlist.coverUrl == null ? Colors.grey[800] : null,
                        ),
                        child: widget.playlist.coverUrl == null
                            ? const Icon(Icons.music_note, size: 60, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.playlist.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.playlist.description != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            widget.playlist.description!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deletePlaylist,
              ),
            ],
          ),
          
          // Play All / Shuffle buttons
          if (!_isLoading && _tracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _playAll(shuffle: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _playAll(shuffle: true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Empty Playlist')),
            )
          else
            SliverReorderableList(
              itemCount: _tracks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _tracks.removeAt(oldIndex);
                  _tracks.insert(newIndex, item);
                });
                // Note: Actual backend reordering not implemented as API doesn't support it yet
              },
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return Dismissible(
                  key: ValueKey(track.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeTrack(track),
                  child: Material(
                    color: theme.scaffoldBackgroundColor, // Needed for proper drag appearance
                    child: Row(
                      children: [
                        // Drag Handle
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16),
                            child: Icon(Icons.drag_indicator, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) => TrackTile(
                              mediaItem: track,
                              isPlaying: player.currentMedia?.id == track.id,
                              onTap: () => _playTrack(track, index),
                              onMoreTap: () => _showTrackOptions(track),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
             // Add padding at bottom for mini player + nav bar
             SliverToBoxAdapter(
                child: SizedBox(height: player.hasMedia ? 180 : 100),
             ),
        ],
      ),
    );
  }
}

