import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/artist.dart';
import '../../../core/services/library_service.dart';
import '../../../core/services/artist_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/track_tile.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  bool _isLoading = true;
  List<MediaItem> _tracks = [];
  late Artist _artist;

  @override
  void initState() {
    super.initState();
    _artist = widget.artist;
    _loadArtistTracks();
  }

  Future<void> _loadArtistTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await context.read<LibraryService>().getArtistTracks(widget.artist.id);
      if (mounted) {
        setState(() {
          _tracks = tracks;
        });
      }
    } catch (e) {
      debugPrint('Error loading artist tracks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Formats large numbers (e.g., 1234 -> "1.2K", 1234567 -> "1.2M")
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const BackButton(color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _artist.imageUrl != null
                      ? Image.network(
                          _artist.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[800]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor,
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_artist.verified)
                          Row(
                            children: const [
                              Icon(Icons.verified, color: AppColors.primary, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Verified Artist',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          _artist.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row + Follow button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(
                        context,
                        label: 'Followers',
                        value: _formatCount(_artist.followerCount),
                        icon: Icons.people_outline_rounded,
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      if (_artist.totalPlays > 0)
                        _buildStatItem(
                          context,
                          label: 'Total Plays',
                          value: _formatCount(_artist.totalPlays),
                          icon: Icons.play_circle_outline_rounded,
                        ),
                      const Spacer(),
                      _buildFollowButton(),
                    ],
                  ),
                  // Bio
                  if (_artist.bio != null && _artist.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _artist.bio!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Genre / Country
                  if (_artist.genre != null || _artist.country != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          if (_artist.genre != null)
                            Chip(
                              label: Text(_artist.genre!),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              side: BorderSide.none,
                              labelStyle: theme.textTheme.bodySmall,
                            ),
                          if (_artist.country != null)
                            Chip(
                              avatar: const Icon(Icons.location_on_outlined, size: 14),
                              label: Text(_artist.country!),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              side: BorderSide.none,
                              labelStyle: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Section title for tracks
          if (!_isLoading && _tracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'Popular',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No tracks found')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _tracks[index];
                  return TrackTile(
                    mediaItem: track,
                    onTap: () {
                       context.read<PlayerProvider>().play(track);
                    },
                  );
                },
                childCount: _tracks.length,
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 140),
             ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    final isFollowing = _artist.following;
    
    return FilledButton.icon(
      onPressed: () => _toggleFollow(context),
      icon: Icon(isFollowing ? Icons.check : Icons.add),
      label: Text(isFollowing ? 'Following' : 'Follow'),
      style: FilledButton.styleFrom(
        backgroundColor: isFollowing ? Colors.transparent : AppColors.primary,
        foregroundColor: Colors.white,
        side: isFollowing ? const BorderSide(color: Colors.white) : null,
      ),
    );
  }

  Future<void> _toggleFollow(BuildContext context) async {
    final artistService = context.read<ArtistService>();
    // Optimistic update
    setState(() {
      _artist = Artist(
        id: _artist.id,
        name: _artist.name,
        imageUrl: _artist.imageUrl,
        genre: _artist.genre,
        country: _artist.country,
        bio: _artist.bio,
        followerCount: _artist.followerCount + (_artist.following ? -1 : 1),
        totalPlays: _artist.totalPlays,
        following: !_artist.following,
        verified: _artist.verified,
      );
    });

    final updatedArtist = await artistService.toggleFollow(widget.artist.id);
    if (updatedArtist != null && mounted) {
      setState(() {
        _artist = updatedArtist;
      });
      // Refresh library to reflect changes
      context.read<LibraryService>().getArtists();
    } else {
      // Revert if failed
       setState(() {
        // Re-revert logic or just re-fetch
      });     
    }
  }
}
