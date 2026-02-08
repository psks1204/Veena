import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/library_service.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';

/// Playlist Detail Screen
/// 
/// Full playlist view with large artwork header and track list.
/// Fetches real tracks from API using LibraryService.
class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
    this.coverUrl,
  });

  final String playlistId;
  final String playlistTitle;
  final String? coverUrl;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> with RouteAware {
  bool _isLiked = false;
  bool _isLoading = true;
  String? _error;
  List<MediaItem> _tracks = [];

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
      final libraryService = context.read<LibraryService>();
      final tracks = await libraryService.getPlaylistTracks(widget.playlistId);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
      debugPrint('[PlaylistDetail] Loaded ${tracks.length} tracks');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading playlist tracks: $e');
    }
  }

  void _playTrack(MediaItem track, {int? trackIndex}) {
    final player = context.read<PlayerProvider>();
    
    // Play the queue starting from this track
    if (_tracks.isNotEmpty && trackIndex != null) {
      player.playQueue(_tracks, startIndex: trackIndex);
    } else {
      player.play(track);
    }
    
    if (track.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_tracks.isNotEmpty) {
      final player = context.read<PlayerProvider>();
      player.playQueue(_tracks, shuffle: shuffle);
    }
  }

  String _formatTotalDuration() {
    // Calculate total duration from tracks if available
    int totalSeconds = _tracks.length * 180; // Estimate ~3min per track
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${_tracks.length} songs, $hours hr ${minutes} min';
    }
    return '${_tracks.length} songs, ${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = (screenWidth * 0.55).clamp(160.0, 280.0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing header with artwork
          SliverAppBar(
            expandedHeight: artworkSize + 180,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(0.3),
                      isDark ? AppColors.darkBg : AppColors.lightBg,
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 56),
                    child: Column(
                      children: [
                        // Artwork
                        Container(
                          width: artworkSize,
                          height: artworkSize,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _buildPlaceholderIcon(artworkSize, colorScheme),
                                  ),
                                )
                              : _buildPlaceholderIcon(artworkSize, colorScheme),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Playlist title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: Text(
                            widget.playlistTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xs),
                        
                        // Playlist info
                        Text(
                          _formatTotalDuration(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Actions row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  
                  // Shuffle button
                  IconButton(
                    onPressed: _tracks.isNotEmpty ? () => _playAll(shuffle: true) : null,
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                  
                  // Play button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _tracks.isNotEmpty ? colorScheme.primary : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _tracks.isNotEmpty ? () => _playAll() : null,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading / Error / Track list
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Failed to load playlist'),
                      TextButton(
                        onPressed: _loadTracks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_tracks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No tracks in this playlist',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Track list - use Selector to only rebuild when current track changes, not on every position update
            Selector<PlayerProvider, String?>(
              selector: (_, player) => player.currentMedia?.id,
              builder: (context, currentPlayingId, _) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = _tracks[index];
                        final isPlaying = currentPlayingId == track.id;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AuraTrackTile(
                            index: index + 1,
                            title: track.title,
                            subtitle: track.artistName,
                            duration: '',
                            imageUrl: track.thumbnailUrl,
                            isPlaying: isPlaying,
                            onTap: () => _playTrack(track, trackIndex: index),
                            onMoreTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddToPlaylistSheet(mediaItem: track),
                              );
                            },
                          ),
                        );
                      },
                      childCount: _tracks.length,
                    ),
                  ),
                );
              },
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(double size, ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.3,
        color: colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}
