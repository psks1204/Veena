import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/library_service.dart';
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

  @override
  void initState() {
    super.initState();
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
                  widget.artist.imageUrl != null
                      ? Image.network(
                          widget.artist.imageUrl!,
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
                        if (widget.artist.verified)
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
                          widget.artist.name,
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
                child: SizedBox(height: 100),
             ),
        ],
      ),
    );
  }
}
