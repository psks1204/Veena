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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
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
                        const SizedBox(height: 16),
                        _buildFollowButton(),
                      ],
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
        followerCount: _artist.followerCount + (_artist.following ? -1 : 1),
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
