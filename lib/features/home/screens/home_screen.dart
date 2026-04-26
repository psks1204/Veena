import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/artist.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/album_service.dart';
import '../../../core/services/library_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/screens/artist_detail_screen.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../library/screens/albums_browse_screen.dart';
import '../../library/screens/album_detail_screen.dart';
import '../../library/screens/artists_browse_screen.dart';
import '../../playlist/screens/playlist_detail_screen.dart';
import '../widgets/featured_carousel.dart';
import 'paginated_section_screen.dart';
import 'simple_section_screen.dart';
import 'featured_playlists_browse_screen.dart';

import '../../../shared/widgets/app_footer.dart';
import '../../../core/services/birthday_service.dart';
import '../../../shared/widgets/birthday_celebration_overlay.dart';
import '../../../shared/widgets/birthday_banner.dart';
import '../../../core/providers/profile_provider.dart';

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
  bool _birthdayChecked = false;
  final BirthdayService _birthdayService = BirthdayService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkBirthday();
    });
  }

  void _checkBirthday() async {
    if (_birthdayChecked) return;
    _birthdayChecked = true;

    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.profile;

    if (user == null) {
      _birthdayChecked = false; // allow retry if profile loads later
      return;
    }

    if (await _birthdayService.shouldShowBirthdayBomb(user)) {
      if (!mounted) return;

      await _birthdayService.markBirthdayBombAsSeen();

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) => BirthdayCelebrationOverlay(
          userName: user.displayName,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = context.read<DashboardService>();

      // Load critical dashboard data first — renders the home screen
      await dashboard.fetchDashboard();

      if (mounted) setState(() => _isLoading = false);

      // Load secondary data in the background (non-blocking)
      // These don't need to complete before showing the home screen
      if (mounted) {
        final albumService = context.read<AlbumService>();
        final libraryService = context.read<LibraryService>();
        unawaited(albumService.getAllAlbums());
        unawaited(libraryService.getFeaturedPlaylists());
      }
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
    player.playQueue(items, startIndex: index);

    final item = items[index];
    if (item.isVideo && !kIsWeb) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()));
    }
  }

  void _toggleLike(MediaItem item) async {
    final mediaService = context.read<MediaService>();
    final libraryService = context.read<LibraryService>();

    await mediaService.toggleLike(item.id, initial: item.liked);

    if (mediaService.isLiked(item.id, initial: item.liked)) {
      libraryService.addFavoriteLocal(item);
    } else {
      libraryService.removeFavoriteLocal(item.id);
    }

    setState(() {});
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

    return Scaffold(
      body: Consumer<DashboardService>(
        builder: (context, dashboard, child) {
          final profileProvider = context.watch<ProfileProvider>();
          final user = profileProvider.profile;
          final isBirthday = _birthdayService.isBirthday(user);

          final latestReleases = dashboard.latestReleases;
          final popularTracks = dashboard.popularTracks;
          final recentlyPlayed = dashboard.recentlyPlayed;
          final audios = dashboard.audios;
          final videos = dashboard.videos;
          final podcasts = dashboard.podcasts;
          final popularPlaylists = dashboard.popularPlaylists;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                _buildHeader(theme),

                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else ...[
                  if (recentlyPlayed.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Recently Played',
                      icon: Icons.history_rounded,
                      items: recentlyPlayed,
                      isHorizontal: true,
                      onSeeAll: () {
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SimpleSectionScreen(
                              title: 'Recently Played',
                              items: recentlyPlayed,
                            ),
                          ),
                        );
                      },
                    ),

                  ..._buildFeaturedPlaylistsSectionSlivers(context),

                  if (popularPlaylists.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Popular Playlists',
                      icon: Icons.playlist_play_rounded,
                      items: popularPlaylists,
                      isHorizontal: true,
                      onSeeAll: () {
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SimpleSectionScreen(
                              title: 'Popular Playlists',
                              items: [],
                            ),
                          ),
                        );
                      },
                    ),

                  if (isBirthday && user != null)
                    SliverToBoxAdapter(
                      child: BirthdayBanner(userName: user.displayName),
                    ),

                  if (audios.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Popular Tracks',
                      icon: Icons.music_note_rounded,
                      items: audios,
                      isHorizontal: true,
                      onSeeAll: () {
                        final mediaService = context.read<MediaService>();
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaginatedSectionScreen(
                              title: 'Popular Tracks',
                              fetchPagedItems: (page, size) =>
                                  mediaService.fetchMedia(
                                    page: page,
                                    size: size,
                                    mediaType: 'AUDIO',
                                  ),
                            ),
                          ),
                        );
                      },
                    ),

                  if (latestReleases.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Latest Releases',
                      icon: Icons.new_releases_rounded,
                      items: latestReleases,
                      isHorizontal: true,
                      onSeeAll: () {
                        final mediaService = context.read<MediaService>();
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaginatedSectionScreen(
                              title: 'Latest Releases',
                              fetchPagedItems: (page, size) => mediaService
                                  .fetchLatestReleases(page: page, size: size),
                            ),
                          ),
                        );
                      },
                    ),

                  if (popularTracks.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Trending Now',
                      icon: Icons.trending_up_rounded,
                      items: popularTracks,
                      isHorizontal: true,
                      onSeeAll: () {
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SimpleSectionScreen(
                              title: 'Trending Now',
                              items: popularTracks,
                            ),
                          ),
                        );
                      },
                    ),

                  ..._buildAlbumsSectionSlivers(context),

                  if (podcasts.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Podcasts',
                      icon: Icons.podcasts_rounded,
                      items: podcasts,
                      isHorizontal: true,
                      onSeeAll: () {
                        final mediaService = context.read<MediaService>();
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaginatedSectionScreen(
                              title: 'Podcasts',
                              fetchPagedItems: (page, size) =>
                                  mediaService.fetchMedia(
                                    page: page,
                                    size: size,
                                    mediaType: 'PODCAST',
                                  ),
                            ),
                          ),
                        );
                      },
                    ),

                  if (videos.isNotEmpty)
                    ..._buildSectionSlivers(
                      context,
                      title: 'Videos',
                      icon: Icons.play_circle_filled_rounded,
                      items: videos,
                      isHorizontal: true,
                      onSeeAll: () {
                        final mediaService = context.read<MediaService>();
                        AppNavigation.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaginatedSectionScreen(
                              title: 'Videos',
                              fetchPagedItems: (page, size) =>
                                  mediaService.fetchMedia(
                                    page: page,
                                    size: size,
                                    mediaType: 'VIDEO',
                                  ),
                            ),
                          ),
                        );
                      },
                    ),

                  if (dashboard.artists.isNotEmpty)
                    ..._buildArtistSectionSlivers(context, dashboard.artists),

                  if (dashboard.audios.isNotEmpty)
                    ..._buildListSectionSlivers(
                      context,
                      title: 'Audio',
                      icon: Icons.music_note_rounded,
                      items: dashboard.audios,
                    ),

                  if (latestReleases.isEmpty &&
                      popularTracks.isEmpty &&
                      recentlyPlayed.isEmpty)
                    _buildEmptyState(),
                ],

                const SliverToBoxAdapter(child: AppFooter()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Consumer<DashboardService>(
        builder: (context, dashboard, _) {
          final featuredItems = dashboard.featuredActive;

          final fallbackLatest = dashboard.latestReleases.take(6).toList();
          final fallbackTrending = dashboard.popularTracks.take(6).toList();

          final carouselItems = featuredItems.isNotEmpty
              ? featuredItems
              : (fallbackLatest.isNotEmpty ? fallbackLatest : fallbackTrending);

          if (carouselItems.isEmpty) return const SizedBox.shrink();

          return FeaturedCarousel(items: carouselItems, onPlay: _playMedia);
        },
      ),
    );
  }

  List<Widget> _buildSectionSlivers(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<dynamic> items,
    bool isHorizontal = false,
    bool showBadge = false,
    VoidCallback? onSeeAll,
  }) {
    final mediaService = context.watch<MediaService>();

    if (items.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              actionLabel: onSeeAll != null ? 'See all' : null,
              onActionTap: onSeeAll,
              padding: const EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: AppSpacing.sm,
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: items.length > 10 ? 10 : items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is MediaItem) {
                    return SizedBox(
                      width: 140,
                      child: AuraAlbumCard(
                        title: item.title,
                        subtitle: item.artistName,
                        imageUrl: item.thumbnailUrl ?? '',
                        mediaType: item.mediaType,
                        isNew: showBadge && index < 3,
                        isLiked: mediaService.isLiked(
                          item.id,
                          initial: item.liked,
                        ),
                        onTap: () => _playMedia(items.cast<MediaItem>(), index),
                        onLikeTap: () => _toggleLike(item),
                        onMoreTap: () {
                          MediaOptionsSheet.show(
                            context,
                            mediaItem: item,
                          );
                        },
                      ),
                    );
                  } else if (item is Playlist) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return _buildPlaylistCard(context, item, isDark);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildListSectionSlivers(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
    VoidCallback? onSeeAll,
  }) {
    final player = context.watch<PlayerProvider>();
    final mediaService = context.watch<MediaService>();

    if (items.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: SectionHeader(
            title: title,
            actionLabel: 'See all',
            onActionTap:
                onSeeAll ??
                () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaginatedSectionScreen(
                        title: title,
                        fetchPagedItems: (page, size) =>
                            mediaService.fetchMedia(
                              page: page,
                              size: size,
                              mediaType: 'AUDIO',
                            ),
                      ),
                    ),
                  );
                },
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            final isPlaying = player.currentMedia?.id == item.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AuraTrackTile(
                title: item.title,
                subtitle: item.artistName,
                imageUrl: item.thumbnailUrl,
                isPlaying: isPlaying,
                isLiked: mediaService.isLiked(item.id, initial: item.liked),
                playedCount: item.playedCount > 0 ? item.playedCount : null,
                likeCount: item.likeCount > 0 ? item.likeCount : null,
                onTap: () => _playMedia(items, index),
                onLikeTap: () => _toggleLike(item),
                onMoreTap: () {
                  MediaOptionsSheet.show(context, mediaItem: item);
                },
              ),
            );
          }, childCount: items.length > 5 ? 5 : items.length),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
    ];
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No content available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new music and videos!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeaturedPlaylistsSectionSlivers(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return [
      Consumer<LibraryService>(
        builder: (context, libraryService, _) {
          final featuredPlaylists = libraryService.featuredPlaylists;

          if (featuredPlaylists.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: SectionHeader(
                    title: 'Featured Playlists',
                    actionLabel: 'See all',
                    onActionTap: () {
                      AppNavigation.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeaturedPlaylistsBrowseScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
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
      ),
    ];
  }

  List<Widget> _buildAlbumsSectionSlivers(BuildContext context) {
    return [
      Consumer<AlbumService>(
        builder: (context, albumService, _) {
          final albums = albumService.albums;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (albums.isEmpty && !albumService.isLoading) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: SectionHeader(
                    title: 'Albums',
                    actionLabel: 'See all',
                    onActionTap: () {
                      AppNavigation.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlbumsBrowseScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: albumService.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: albums.length > 10 ? 10 : albums.length,
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
      ),
    ];
  }

  List<Widget> _buildArtistSectionSlivers(
    BuildContext context,
    List<Artist> artists,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: SectionHeader(
                title: 'Artists',
                actionLabel: 'See all',
                onActionTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtistsBrowseScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: artists.length > 10 ? 10 : artists.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () {
                      AppNavigation.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(artist: artist),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 110,
                      child: Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: artist.imageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        artist.imageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                            child: artist.imageUrl == null
                                ? Center(
                                    child: Text(
                                      artist.name.isNotEmpty
                                          ? artist.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildPlaylistCard(
    BuildContext context,
    Playlist playlist,
    bool isDark,
  ) {
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
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: playlist.coverUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheWidth: 280,
                  placeholder: (_, __) => Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: const Icon(Icons.playlist_play_rounded, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${playlist.trackCount} songs',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(
    BuildContext context,
    AlbumSummary album,
    bool isDark,
  ) {
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
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: album.coverUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheWidth: 280,
                  placeholder: (_, __) => Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: const Icon(Icons.album_rounded, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artistName,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
