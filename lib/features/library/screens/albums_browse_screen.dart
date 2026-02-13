import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/album_service.dart';
import '../../../core/navigation/app_navigation.dart';
import 'album_detail_screen.dart';

/// Albums Browse Screen
/// 
/// Spotify-like grid display of all albums with search capability.
class AlbumsBrowseScreen extends StatefulWidget {
  const AlbumsBrowseScreen({super.key});

  @override
  State<AlbumsBrowseScreen> createState() => _AlbumsBrowseScreenState();
}

class _AlbumsBrowseScreenState extends State<AlbumsBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Defer to post-frame to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlbums();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    final albumService = context.read<AlbumService>();
    await albumService.getAllAlbums();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<AlbumSummary> _getFilteredAlbums(List<AlbumSummary> albums) {
    if (_searchQuery.isEmpty) return albums;
    return albums.where((album) {
      return album.title.toLowerCase().contains(_searchQuery) ||
             album.artistName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with search
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: _isSearching ? 120 : 80,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Search albums...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    onChanged: _onSearch,
                  )
                : Text(
                    'Albums',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
            ],
          ),

          // Albums Grid
          Consumer<AlbumService>(
            builder: (context, albumService, _) {
              if (albumService.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (albumService.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load albums',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadAlbums,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final albums = _getFilteredAlbums(albumService.albums);

              if (albums.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.album_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No albums available'
                              : 'No albums found for "$_searchQuery"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.lg,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final album = albums[index];
                      return _AlbumCard(
                        album: album,
                        onTap: () => _navigateToAlbum(album),
                      );
                    },
                    childCount: albums.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding for mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
    );
  }

  void _navigateToAlbum(AlbumSummary album) {
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
  }
}

/// Album Card Widget - Spotify-like design
class _AlbumCard extends StatelessWidget {
  final AlbumSummary album;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Cover with shadow
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    album.coverUrl != null && album.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: album.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildPlaceholder(colorScheme),
                            errorWidget: (_, __, ___) => _buildPlaceholder(colorScheme),
                          )
                        : _buildPlaceholder(colorScheme),
                    
                    // Play button overlay on hover/tap
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Album title
          Text(
            album.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 2),
          
          // Artist name and track count
          Text(
            '${album.artistName} • ${album.trackCount} ${album.trackCount == 1 ? 'song' : 'songs'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.album_rounded,
        size: 48,
        color: colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}
