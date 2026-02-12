import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';

/// Search Screen
/// 
/// Premium search experience with:
/// - Real-time API search with debouncing
/// - Browse categories
/// - Search results with tracks, artists, albums
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final mediaService = context.read<MediaService>();
      final results = await mediaService.search(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
      debugPrint('Search error: $e');
    }
  }

  void _playMedia(MediaItem item) {
    final player = context.read<PlayerProvider>();
    final mediaService = context.read<MediaService>();
    
    player.play(item);
    // mediaService.recordPlay(item.id); // Track analytics (Handled by PlayerProvider)

    if (item.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  void _toggleLike(MediaItem item) async {
    final mediaService = context.read<MediaService>();
    await mediaService.toggleLike(item.id);
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MediaService>().clearSearch();
    setState(() {
      _isSearching = false;
      _hasSearched = false;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with search
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            title: Text(
              'Search',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you want to listen to?',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_hasSearched)
            _buildSearchResults(theme)
          else
            _buildBrowseCategories(theme, colorScheme),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    final mediaService = context.watch<MediaService>();
    final player = context.watch<PlayerProvider>();
    
    if (_searchResults.isEmpty) {
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
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No results found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Separate by type
    final videos = _searchResults.where((m) => m.isVideo).toList();
    final audios = _searchResults.where((m) => m.isAudio).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Results count
          Text(
            '${_searchResults.length} results',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Videos section
          if (videos.isNotEmpty) ...[
            Text(
              'Videos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = videos[index];
                  return SizedBox(
                    width: 160,
                    child: AuraAlbumCard(
                      title: item.title,
                      subtitle: item.description ?? '',
                      imageUrl: item.thumbnailUrl ?? '',
                      mediaType: item.mediaType,
                      isLiked: mediaService.isLiked(item.id),
                      onTap: () => _playMedia(item),
                      onLikeTap: () => _toggleLike(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Audio tracks section
          if (audios.isNotEmpty) ...[
            Text(
              'Tracks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...audios.map((item) {
              final isPlaying = player.currentMedia?.id == item.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AuraTrackTile(
                  title: item.title,
                  subtitle: item.description ?? '',
                  imageUrl: item.thumbnailUrl,
                  isPlaying: isPlaying,
                  isLiked: mediaService.isLiked(item.id),
                  onTap: () => _playMedia(item),
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
            }),
          ],
        ]),
      ),
    );
  }

  Widget _buildBrowseCategories(ThemeData theme, ColorScheme colorScheme) {
    final categories = [
      _CategoryData('Podcasts', const Color(0xFF27856A)),
      _CategoryData('Made For You', const Color(0xFF1E3264)),
      _CategoryData('Charts', const Color(0xFF8D67AB)),
      _CategoryData('New Releases', const Color(0xFFE8115B)),
      _CategoryData('Discover', const Color(0xFFE13300)),
      _CategoryData('Concerts', const Color(0xFF148A08)),
      _CategoryData('Pop', const Color(0xFF509BF5)),
      _CategoryData('Hip-Hop', const Color(0xFFBA5D07)),
      _CategoryData('Rock', const Color(0xFFE61E32)),
      _CategoryData('Latin', const Color(0xFFE13300)),
      _CategoryData('Dance/Electronic', const Color(0xFF8D67AB)),
      _CategoryData('Indie', const Color(0xFF608108)),
      _CategoryData('Workout', const Color(0xFF777777)),
      _CategoryData('R&B', const Color(0xFFDC148C)),
      _CategoryData('Mood', const Color(0xFF503750)),
      _CategoryData('Jazz', const Color(0xFF477D95)),
    ];

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Browse all',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.6,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                return _CategoryCard(
                  title: category.title,
                  color: category.color,
                  onTap: () {},
                );
              },
              childCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData(this.title, this.color);
  final String title;
  final Color color;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Stack(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Decorative element
            Positioned(
              right: -8,
              bottom: -4,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
