import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/services/library_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/media_item.dart';
import '../../../shared/widgets/track_list_tile.dart';
import '../../../shared/widgets/add_to_playlist_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<MediaItem> _tracks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracks = await context.read<LibraryProvider>().getPlaylistTracks(widget.playlist.id);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromPlaylist(MediaItem track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Playlist'),
        content: Text('Remove "${track.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<LibraryProvider>().removeFromPlaylist(
        widget.playlist.id,
        track.id,
      );

      if (success) {
        setState(() {
          _tracks.removeWhere((t) => t.id == track.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${track.title}" from playlist')),
          );
        }
      }
    }
  }

  void _playAll() {
    if (_tracks.isNotEmpty) {
      context.read<PlaybackProvider>().setQueue(_tracks, initialStateIndex: 0);
    }
  }

  void _shufflePlay() {
    if (_tracks.isNotEmpty) {
      final shuffled = List<MediaItem>.from(_tracks)..shuffle();
      context.read<PlaybackProvider>().setQueue(shuffled, initialStateIndex: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with playlist cover
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      isDark ? AppColors.darkBg : Colors.white,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Playlist cover
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.playlist.coverUrl != null
                            ? Image.network(
                                widget.playlist.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaylistIcon(),
                              )
                            : _buildPlaylistIcon(),
                      ),
                      const SizedBox(height: 16),
                      // Playlist name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.playlist.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.playlist.trackCount} tracks',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _tracks.isEmpty ? null : _playAll,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _tracks.isEmpty ? null : _shufflePlay,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tracks list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTracks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_tracks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs in this playlist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add songs from the home screen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _tracks[index];
                    final playbackProvider = context.watch<PlaybackProvider>();
                    final isPlaying = playbackProvider.currentMedia?.id == track.id;

                    return Dismissible(
                      key: Key(track.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _removeFromPlaylist(track);
                        return false; // We handle removal manually
                      },
                      child: TrackListTile(
                        title: track.title,
                        artist: track.artistName,
                        artworkUrl: track.thumbnailUrl,
                        trackNumber: index + 1,
                        isPlaying: isPlaying,
                        onTap: () {
                          context.read<PlaybackProvider>().setQueue(
                            _tracks,
                            initialStateIndex: index,
                          );
                        },
                        onMoreTap: () {
                          _showTrackOptions(track);
                        },
                      ),
                    );
                  },
                  childCount: _tracks.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistIcon() {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: const Icon(
        Icons.queue_music_rounded,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }

  void _showTrackOptions(MediaItem track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlaybackProvider>().playMedia(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Another Playlist'),
              onTap: () {
                Navigator.pop(context);
                showAddToPlaylistSheet(context, track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Remove from Playlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeFromPlaylist(track);
              },
            ),
          ],
        ),
      ),
    );
  }
}
