import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/library_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../player/screens/unified_player_screen.dart';

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
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
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
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
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
                child: (track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty)
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
    final isWeb = MediaQuery.of(context).size.width >= 900;
    
    return Scaffold(
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(theme),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return CustomScrollView(
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black45, offset: Offset(0, 10))],
                          image: (widget.playlist.coverUrl != null && widget.playlist.coverUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.playlist.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: (widget.playlist.coverUrl == null || widget.playlist.coverUrl!.isEmpty) 
                              ? Colors.grey[800] 
                              : null,
                        ),
                        child: (widget.playlist.coverUrl == null || widget.playlist.coverUrl!.isEmpty)
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
                        textAlign: TextAlign.center,
                      ),
                      if (widget.playlist.description != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            widget.playlist.description!,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
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
                  color: theme.scaffoldBackgroundColor, 
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16),
                          child: Icon(Icons.drag_indicator, color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Selector<PlayerProvider, String?>(
                          selector: (_, player) => player.currentMedia?.id,
                          builder: (context, currentPlayingId, _) => TrackTile(
                            mediaItem: track,
                            isPlaying: currentPlayingId == track.id,
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
          
           // Add padding at bottom
           Selector<PlayerProvider, bool>(
             selector: (_, player) => player.hasMedia,
             builder: (context, hasMedia, _) => SliverToBoxAdapter(
               child: SizedBox(height: hasMedia ? 160 : 80),
             ),
           ),
      ],
    );
  }

  Widget _buildWebLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();

    return Stack(
      children: [
        // Ambient background
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
          ),
        ),
        
        Row(
          children: [
            // Left Side: Artwork & Info
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Artwork
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        image: (widget.playlist.coverUrl != null && widget.playlist.coverUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(widget.playlist.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: (widget.playlist.coverUrl == null || widget.playlist.coverUrl!.isEmpty) 
                            ? Colors.grey[800] 
                            : null,
                      ),
                      child: (widget.playlist.coverUrl == null || widget.playlist.coverUrl!.isEmpty)
                          ? const Icon(Icons.music_note, size: 80, color: Colors.white24)
                          : null,
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      widget.playlist.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    if (widget.playlist.description != null)
                      Text(
                        widget.playlist.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(Icons.playlist_play, '${_tracks.length} Tracks', isDark),
                        const SizedBox(width: 24),
                        _buildStatItem(Icons.account_circle, 'My Playlist', isDark),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _tracks.isNotEmpty ? () => _playAll(shuffle: false) : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _tracks.isNotEmpty ? () => _playAll(shuffle: true) : null,
                          icon: const Icon(Icons.shuffle_rounded),
                          color: isDark ? Colors.white : Colors.black,
                          tooltip: 'Shuffle',
                          padding: const EdgeInsets.all(16),
                        ),
                        IconButton(
                          onPressed: _deletePlaylist,
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Delete Playlist',
                          padding: const EdgeInsets.all(16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Right Side: Tracks
            Expanded(
              flex: 3,
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 60, 32, 16),
                      child: Text(
                        'PLAYLIST TRACKS',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _tracks.isEmpty
                          ? const Center(child: Text('No tracks in this playlist'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final track = _tracks[index];
                                final isPlaying = player.currentMedia?.id == track.id;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TrackTile(
                                    mediaItem: track,
                                    isPlaying: isPlaying,
                                    onTap: () => _playTrack(track, index),
                                    onMoreTap: () => _showTrackOptions(track),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    SizedBox(height: player.hasMedia ? 120 : 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // App Bar / Back
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                BackButton(color: isDark ? Colors.white : Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

