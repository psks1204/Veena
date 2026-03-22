import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/artist.dart';
import '../../../../core/services/artist_service.dart';
import '../../../../core/navigation/app_navigation.dart';
import 'artist_detail_screen.dart';

/// Artists Browse Screen
///
/// Spotify-like grid display of all artists with search capability.
class ArtistsBrowseScreen extends StatefulWidget {
  const ArtistsBrowseScreen({super.key});

  @override
  State<ArtistsBrowseScreen> createState() => _ArtistsBrowseScreenState();
}

class _ArtistsBrowseScreenState extends State<ArtistsBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<Artist> _artists = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtists();
    });
  }

  void _onScroll() {
    if (_searchQuery.isNotEmpty) return; // Disable pagination during search for simplicity
    
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasMore) {
        _loadMoreArtists();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final artistService = context.read<ArtistService>();
      final response = await artistService.getAllArtists(page: 0);
      if (mounted) {
        setState(() {
          _artists = response.content;
          _hasMore = !response.isLast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load artists';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreArtists() async {
    if (_isFetchingMore || !_hasMore || _searchQuery.isNotEmpty) return;

    setState(() => _isFetchingMore = true);

    try {
      final artistService = context.read<ArtistService>();
      final nextPage = _currentPage + 1;
      final response = await artistService.getAllArtists(page: nextPage);
      
      if (mounted) {
        setState(() {
          _artists.addAll(response.content);
          _currentPage = nextPage;
          _hasMore = !response.isLast;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more artists: $e');
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Artist> _getFilteredArtists() {
    if (_searchQuery.isEmpty) return _artists;
    return _artists.where((artist) {
      return artist.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
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
                      hintText: 'Search artists...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    onChanged: _onSearch,
                  )
                : Text(
                    'Artists',
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

          // Artists Grid
          _buildContent(theme, colorScheme),

          // Bottom padding for mini player
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _loadArtists,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredArtists = _getFilteredArtists();

    if (filteredArtists.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _searchQuery.isEmpty
                    ? 'No artists available'
                    : 'No artists found for "$_searchQuery"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.8,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final artist = filteredArtists[index];
              return _ArtistCard(
                artist: artist,
                onTap: () => _navigateToArtist(artist),
              );
            }, childCount: filteredArtists.length),
          ),
        ),
        if (_isFetchingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToArtist(Artist artist) {
    AppNavigation.push(
      context,
      MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: artist)),
    );
  }
}

/// Artist Card Widget - circular profile layout
class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistCard({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Circular Image
          AspectRatio(
            aspectRatio: 1,
            child: Container(
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
                        image: NetworkImage(artist.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: artist.imageUrl == null
                  ? Center(
                      child: Text(
                        artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Artist Name
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
    );
  }
}
