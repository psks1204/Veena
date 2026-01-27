import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/track_list_tile.dart';

/// Playlist Detail Screen
/// 
/// Full playlist view with large artwork header and track list.
class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
  });

  final String playlistId;
  final String playlistTitle;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLiked = false;
  bool _isShuffleOn = false;

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
                          child: Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: artworkSize * 0.3,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
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
                          'Made for You • 50 songs, 2 hr 45 min',
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
                  // Like button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isLiked = !_isLiked;
                      });
                    },
                    icon: Icon(
                      _isLiked 
                          ? Icons.favorite_rounded 
                          : Icons.favorite_border_rounded,
                      color: _isLiked ? AppColors.primary : null,
                    ),
                  ),
                  
                  // Download button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined),
                  ),
                  
                  // More options
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                  
                  const Spacer(),
                  
                  // Shuffle button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isShuffleOn = !_isShuffleOn;
                      });
                    },
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: _isShuffleOn ? colorScheme.primary : null,
                    ),
                  ),
                  
                  // Play button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
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
                      onPressed: () {},
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

          // Track list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tracks = _getMockTracks();
                final track = tracks[index];
                return TrackListTile(
                  title: track.title,
                  artist: track.artist,
                  duration: track.duration,
                  trackNumber: index + 1,
                  isExplicit: track.isExplicit,
                  isPlaying: index == 0, // First track playing
                  onTap: () {},
                  onMoreTap: () {},
                );
              },
              childCount: _getMockTracks().length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  List<_Track> _getMockTracks() {
    return [
      _Track('Blinding Lights', 'The Weeknd', const Duration(minutes: 3, seconds: 20)),
      _Track('Save Your Tears', 'The Weeknd', const Duration(minutes: 3, seconds: 35), isExplicit: true),
      _Track('Starboy', 'The Weeknd ft. Daft Punk', const Duration(minutes: 3, seconds: 50)),
      _Track('Die For You', 'The Weeknd', const Duration(minutes: 3, seconds: 15)),
      _Track('Call Out My Name', 'The Weeknd', const Duration(minutes: 3, seconds: 48)),
      _Track('In Your Eyes', 'The Weeknd', const Duration(minutes: 3, seconds: 57)),
      _Track('After Hours', 'The Weeknd', const Duration(minutes: 6, seconds: 1)),
      _Track('Heartless', 'The Weeknd', const Duration(minutes: 3, seconds: 18), isExplicit: true),
      _Track('The Hills', 'The Weeknd', const Duration(minutes: 4, seconds: 2)),
      _Track('Often', 'The Weeknd', const Duration(minutes: 4, seconds: 9), isExplicit: true),
    ];
  }
}

class _Track {
  const _Track(this.title, this.artist, this.duration, {this.isExplicit = false});
  final String title;
  final String artist;
  final Duration duration;
  final bool isExplicit;
}
