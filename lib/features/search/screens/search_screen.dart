import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/search_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/media_item.dart';

/// Search Screen
/// 
/// Premium search experience with browse categories.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with search
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              'Search',
              style: theme.textTheme.headlineMedium,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {
                      _isSearching = value.isNotEmpty;
                    });
                    searchProvider.search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _isSearching
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                              });
                              searchProvider.search('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // Search results or browse categories
          if (_isSearching)
            _buildSearchResults(theme, searchProvider)
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

  Widget _buildSearchResults(ThemeData theme, SearchProvider provider) {
    if (provider.state == SearchState.loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.state == SearchState.error) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('Error: ${provider.errorMessage}'),
        ),
      );
    }

    final results = provider.results;

    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'No results found for "${_searchController.text}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = results[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.thumbnailUrl ?? 'https://picsum.photos/64/64',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note),
                ),
              ),
            ),
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.artistName, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: item.mediaType == 'VIDEO' 
                ? const Icon(Icons.videocam_rounded, size: 20)
                : null,
            onTap: () {
              context.read<PlaybackProvider>().playMedia(item);
            },
          );
        },
        childCount: results.length,
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
                style: theme.textTheme.headlineSmall,
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
            
            // Decorative image placeholder
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
