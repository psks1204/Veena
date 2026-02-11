import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/album_service.dart';
import '../../../core/services/library_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../library/screens/albums_browse_screen.dart';
import '../../library/screens/album_detail_screen.dart';
import '../../playlist/screens/playlist_detail_screen.dart';
import '../widgets/featured_carousel.dart';
import 'section_view_screen.dart';

/// Home Screen - Premium Studio Design
/// 
/// Dynamic home screen with personalized sections:
/// - Recently Played (personalized)
/// - Latest Releases
/// - Popular/Trending
/// - Videos & Audio sections
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = context.read<DashboardService>();
      final albumService = context.read<AlbumService>();
      final libraryService = context.read<LibraryService>();
      
      // Load dashboard, albums, and featured playlists concurrently
      await Future.wait([
        dashboard.fetchDashboard(),
        albumService.getAllAlbums(),
        libraryService.getFeaturedPlaylists(),
      ]);
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playMedia(List<MediaItem> items, int index) {
    final player = context.read<PlayerProvider>();
    final mediaService = context.read<MediaService>();
    
    player.playQueue(items, startIndex: index);
    
    final item = items[index];
    mediaService.recordPlay(item.id); // Track analytics

    if (item.isVideo && !kIsWeb) {
      // Use rootNavigator to open fullscreen on top of everything
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  void _toggleLike(MediaItem item) async {
    final mediaService = context.read<MediaService>();
    await mediaService.toggleLike(item.id);
    setState(() {}); // Refresh UI
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Consumer<DashboardService>(
        builder: (context, dashboard, child) {
          final latestReleases = dashboard.latestReleases;
          final popularTracks = dashboard.popularTracks;
          final recentlyPlayed = dashboard.recentlyPlayed;
          
          // Split by type
          final videos = latestReleases.where((m) => m.isVideo).toList();
          final audios = latestReleases.where((m) => m.isAudio).toList();
          
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // Header
                _buildHeader(theme),

                // Loading State
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else ...[
                  // Recently Played (if available)
                  if (recentlyPlayed.isNotEmpty) ...[
                    _buildSection(
                      context,
                      title: 'Continue Listening',
                      icon: Icons.history_rounded,
                      items: recentlyPlayed,
                      isHorizontal: true,
                    ),
                  ],

                  // Featured Playlists
                  _buildFeaturedPlaylistsSection(context),

                  // Latest Releases
                  if (latestReleases.isNotEmpty) ...[
                    _buildSection(
                      context,
                      title: 'Latest Releases',
                      icon: Icons.new_releases_rounded,
                      items: latestReleases,
                      isHorizontal: true,
                      showBadge: true,
                    ),
                  ],

                  // Popular/Trending
                  if (popularTracks.isNotEmpty) ...[
                    _buildSection(
                      context,
                      title: 'Trending Now',
                      icon: Icons.trending_up_rounded,
                      items: popularTracks,
                      isHorizontal: true,
                    ),
                  ],

                  // Albums Section
                  _buildAlbumsSection(context),

                  // Videos Grid
                  if (videos.isNotEmpty) ...[
                    _buildGridSection(
                      context,
                      title: 'Videos',
                      icon: Icons.play_circle_filled_rounded,
                      items: videos,
                    ),
                  ],

                  // Audio List
                  if (audios.isNotEmpty) ...[
                    _buildListSection(
                      context,
                      title: 'Audio',
                      icon: Icons.music_note_rounded,
                      items: audios,
                    ),
                  ],

                  // Empty state
                  if (latestReleases.isEmpty && 
                      popularTracks.isEmpty && 
                      recentlyPlayed.isEmpty)
                    _buildEmptyState(),
                ],

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    // Interactive Hero Carousel - Shows top 5 latest releases
    return SliverToBoxAdapter(
      child: Consumer<DashboardService>(
        builder: (context, dashboard, _) {
           final featuredItems = dashboard.latestReleases.take(5).toList();
           
           if (featuredItems.isEmpty) return const SizedBox.shrink();

           return FeaturedCarousel(
             items: featuredItems,
             onPlay: _playMedia,
           );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
    bool isHorizontal = false,
    bool showBadge = false,
  }) {
    final mediaService = context.watch<MediaService>();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            actionLabel: 'See all',
            onActionTap: () {
               AppNavigation.push(
                context, 
                MaterialPageRoute(builder: (_) => SectionViewScreen(
                  title: title,
                  items: items,
                )),
              );
            },
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.sm,
            ),
          ),
          SizedBox(
            height: 200, // Reduced height for compact look
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length > 10 ? 10 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 140, // Smaller tiles for better rhythm
                  child: AuraAlbumCard(
                    title: item.title,
                    subtitle: item.artistName,
                    imageUrl: item.thumbnailUrl ?? '',
                    mediaType: item.mediaType,
                    isNew: showBadge && index < 3,
                    isLiked: mediaService.isLiked(item.id),
                    onTap: () => _playMedia(items, index),
                    onLikeTap: () => _toggleLike(item),
                    onMoreTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddToPlaylistSheet(mediaItem: item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg), // Space before next section
        ],
      ),
    );
  }

  Widget _buildGridSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: SectionHeader(
              title: title,
              actionLabel: 'See all',
              onActionTap: () {
                AppNavigation.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionViewScreen(
                      title: title,
                      items: items,
                    ),
                  ),
                );
              },
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length > 6 ? 6 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AuraAlbumCard(
                title: item.title,
                subtitle: item.artistName,
                imageUrl: item.thumbnailUrl ?? '',
                mediaType: item.mediaType,
                onTap: () => _playMedia(items, index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
  }) {
    final player = context.watch<PlayerProvider>();
    final mediaService = context.watch<MediaService>();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: SectionHeader(
              title: title,
              actionLabel: 'See all',
              onActionTap: () {
                AppNavigation.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionViewScreen(
                      title: title,
                      items: items,
                    ),
                  ),
                );
              },
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            itemCount: items.length > 5 ? 5 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isPlaying = player.currentMedia?.id == item.id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AuraTrackTile(
                  title: item.title,
                  subtitle: item.artistName,
                  imageUrl: item.thumbnailUrl,
                  isPlaying: isPlaying,
                  isLiked: mediaService.isLiked(item.id),
                  onTap: () => _playMedia(items, index),
                  onLikeTap: () => _toggleLike(item),
                  onMoreTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddToPlaylistSheet(mediaItem: item),
                      );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPlaylistsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<LibraryService>(
      builder: (context, libraryService, _) {
        final featuredPlaylists = libraryService.featuredPlaylists;
        
        if (featuredPlaylists.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Featured Playlists',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Playlist Cards Horizontal Scroll
              SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = featuredPlaylists[index];
                    return _buildPlaylistCard(context, playlist, isDark);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist, bool isDark) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        AppNavigation.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
              playlistId: playlist.id,
              playlistTitle: playlist.name,
              coverUrl: playlist.coverUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist Cover
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: playlist.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.playlist_play_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 48,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.playlist_play_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.playlist_play_rounded,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          size: 48,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Title
            Text(
              playlist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Track count
            Text(
              '${playlist.trackCount} songs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<AlbumService>(
      builder: (context, albumService, _) {
        final albums = albumService.albums;
        
        if (albums.isEmpty && !albumService.isLoading) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.album_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Albums',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlbumsBrowseScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Album Cards Horizontal Scroll
              SizedBox(
                height: 200,
                child: albumService.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                        scrollDirection: Axis.horizontal,
                        itemCount: albums.length > 10 ? 10 : albums.length, // Limit to 10 items
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return _buildAlbumCard(context, album, isDark);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumCard(BuildContext context, AlbumSummary album, bool isDark) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        AppNavigation.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(
              albumId: album.id,
              title: album.title,
              artist: album.artistName,
              coverUrl: album.coverUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: album.coverUrl != null && album.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: album.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.album_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 48,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.album_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.album_rounded,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          size: 48,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Title
            Text(
              album.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Artist
            Text(
              album.artistName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_music_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No content yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover new music in search',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
