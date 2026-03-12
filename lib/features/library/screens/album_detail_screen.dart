import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/album_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../core/services/artist_service.dart';
import '../../../core/services/library_service.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../../shared/layouts/player_overlay_shell.dart';

/// Album Detail Screen - Neon Horizon
/// 
/// Immersive detail view with rotating vinyl animation.
/// Now fetches real album data from the API.
class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  
  const AlbumDetailScreen({
    super.key, 
    required this.albumId,
    // Accepting basic info to show immediately before loading full details
    this.coverUrl, 
    this.title, 
    this.artist,
  });

  final String? coverUrl;
  final String? title;
  final String? artist;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _rotationController;
  double _opacity = 0.0;
  
  AlbumDetail? _album;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Load album details from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlbumDetails();
    });
  }

  Future<void> _loadAlbumDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final albumService = context.read<AlbumService>();
      final albumId = int.tryParse(widget.albumId) ?? 0;
      final album = await albumService.getAlbumDetails(albumId);
      
      setState(() {
        _album = album;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading album: $e');
    }
  }

  void _playTrack(MediaItem track, {int? trackIndex}) {
    final player = context.read<PlayerProvider>();
    
    // If we have an album with tracks, play the queue starting from this track
    if (_album != null && _album!.tracks.isNotEmpty && trackIndex != null) {
      player.playQueue(_album!.tracks, startIndex: trackIndex);
    } else {
      player.play(track);
    }
    
    if (track.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }
  
  void _playAllTracks({bool shuffle = false}) {
    if (_album != null && _album!.tracks.isNotEmpty) {
      final player = context.read<PlayerProvider>();
      player.playQueue(_album!.tracks, shuffle: shuffle);
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // Fade in sticky header background
    setState(() {
      _opacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Get display values (prefer API data, fall back to passed props)
  String get _displayTitle => _album?.name ?? widget.title ?? 'Album';
  String get _displayArtist => widget.artist ?? 'Artist';
  String get _displayCover => _album?.coverImageUrl ?? widget.coverUrl ?? 'https://picsum.photos/400';
  int get _trackCount => _album?.tracks.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();

    final iconColor = Color.lerp(Colors.white, isDark ? Colors.white : Colors.black, _opacity);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: BackButton(color: iconColor),
        backgroundColor: (isDark ? AppColors.darkBg : AppColors.lightBg).withOpacity(_opacity),
        elevation: 0,
        title: Opacity(
          opacity: _opacity,
          child: Text(
            _displayTitle,
            style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.favorite_border, color: iconColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: iconColor),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
             child: Container(
               color: isDark ? AppColors.darkBg : AppColors.lightBg,
             ),
          ),
          Positioned(
             top: 0,
             left: 0,
             right: 0,
             height: 500,
             child: Container(
               decoration: BoxDecoration(
                 image: DecorationImage(
                   image: CachedNetworkImageProvider(_displayCover),
                   fit: BoxFit.cover,
                   colorFilter: ColorFilter.mode(
                     Colors.black.withOpacity(0.6), 
                     BlendMode.darken
                   ),
                 ),
               ),
               child: Container(
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [
                       Colors.transparent,
                       isDark ? AppColors.darkBg : AppColors.lightBg,
                     ],
                   ),
                 ),
               ),
             ),
          ),

          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                 child: Padding(
                   padding: EdgeInsets.only(
                     top: MediaQuery.of(context).padding.top + 60,
                     bottom: AppSpacing.xl,
                   ),
                   child: Column(
                     children: [
                       // Rotating Vinyl Hero
                       GestureDetector(
                         onTap: () {
                           if (_rotationController.isAnimating) {
                             _rotationController.stop();
                           } else {
                             _rotationController.repeat();
                           }
                         },
                         child: AnimatedBuilder(
                           animation: _rotationController,
                           builder: (context, child) {
                             return Transform.rotate(
                               angle: _rotationController.value * 2 * math.pi,
                               child: child,
                             );
                           },
                           child: Container(
                             width: 240,
                             height: 240,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               image: DecorationImage(
                                 image: CachedNetworkImageProvider(_displayCover),
                                 fit: BoxFit.cover,
                               ),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.4),
                                   blurRadius: 30,
                                   spreadRadius: -5,
                                   offset: const Offset(0, 20),
                                 ),
                               ],
                               border: Border.all(
                                 color: Colors.white.withOpacity(0.1),
                                 width: 8,
                               ),
                             ),
                             child: Center(
                               child: Container(
                                 width: 20,
                                 height: 20,
                                 decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                 ),
                               ),
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(height: AppSpacing.xxl),
                       
                       // Album Info
                       Text(
                         _displayTitle,
                         style: theme.textTheme.displaySmall?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: AppSpacing.xs),
                       Text(
                         _displayArtist,
                         style: theme.textTheme.titleMedium?.copyWith(
                           color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                         ),
                         textAlign: TextAlign.center,
                       ),
                       if (_album?.description != null) ...[
                         const SizedBox(height: AppSpacing.sm),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                           child: Text(
                             _album!.description!,
                             style: theme.textTheme.bodySmall?.copyWith(
                               color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                             ),
                             textAlign: TextAlign.center,
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                       ],
                       const SizedBox(height: AppSpacing.lg),
                       
                       // Actions
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           // Play Button
                           Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _trackCount > 0 ? () => _playAllTracks() : null,
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              ),
                           ),
                           const SizedBox(width: AppSpacing.lg),
                           // Follow Button
                           if (_album != null && _album!.tracks.isNotEmpty && _album!.tracks.first.artistId != null)
                             Consumer<ArtistService>(
                               builder: (context, artistService, _) {
                                 final artistId = _album!.tracks.first.artistId!;
                                 final library = context.watch<LibraryService>();
                                 final isFollowing = library.artists.any((a) => a.id == artistId);
                                 
                                 return IconButton(
                                   onPressed: () async {
                                     await artistService.toggleFollow(artistId);
                                     await context.read<LibraryService>().getArtists();
                                   },
                                   icon: Icon(
                                     isFollowing ? Icons.check_circle : Icons.person_add_alt_1_rounded,
                                     size: 28,
                                   ),
                                   color: isFollowing ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                                 );
                               }
                             ),
                           if (_album != null && _album!.tracks.isNotEmpty && _album!.tracks.first.artistId != null)
                             const SizedBox(width: AppSpacing.lg),

                           // Shuffle
                           IconButton(
                             onPressed: _trackCount > 0 ? () => _playAllTracks(shuffle: true) : null,
                             icon: const Icon(Icons.shuffle_rounded, size: 28),
                             color: isDark ? Colors.white : Colors.black,
                           ),
                         ],
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
                          const Text('Failed to load album'),
                          TextButton(
                            onPressed: _loadAlbumDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_album != null)
                // Tracklist from API
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = _album!.tracks[index];
                        final isPlaying = player.currentMedia?.id == track.id;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AuraTrackTile(
                            index: index + 1,
                            title: track.title,
                            subtitle: track.artistName,
                            duration: '', // Duration could be added to MediaItem if API provides it
                            imageUrl: track.thumbnailUrl,
                            isPlaying: isPlaying,
                            playedCount: track.playedCount > 0 ? track.playedCount : null,
                            likeCount: track.likeCount > 0 ? track.likeCount : null,
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
                      childCount: _album!.tracks.length,
                    ),
                  ),
                ),
              
               // Bottom padding for mini player + nav bar
               SliverToBoxAdapter(
                  child: SizedBox(height: player.hasMedia ? 180 : 100),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
