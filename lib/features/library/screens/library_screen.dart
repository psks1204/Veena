import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/artwork_card.dart';

/// Library Screen
/// 
/// User's playlists, albums, and artists with filtering and sorting.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _currentFilter = LibraryFilter.all;
  bool _isGridView = false;
  LibrarySort _sortBy = LibrarySort.recent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              children: [
                // User avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Your Library',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: LibraryFilter.values.map((filter) {
                  final isSelected = _currentFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _currentFilter = selected ? filter : LibraryFilter.all;
                        });
                      },
                      showCheckmark: false,
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : colorScheme.onSurface,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Sort and view toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Sort button
                  InkWell(
                    onTap: _showSortOptions,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 20,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _sortBy.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // View toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    icon: Icon(
                      _isGridView 
                          ? Icons.view_list_rounded 
                          : Icons.grid_view_rounded,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Library items
          _isGridView
              ? _buildGridView(theme)
              : _buildListView(theme),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ThemeData theme) {
    final items = _getLibraryItems();
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _LibraryListItem(
            title: item.title,
            subtitle: item.subtitle,
            imageUrl: item.imageUrl,
            isCircular: item.type == LibraryItemType.artist,
            isPinned: item.isPinned,
            onTap: () {},
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildGridView(ThemeData theme) {
    final items = _getLibraryItems();
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return ArtworkCard(
              imageUrl: item.imageUrl,
              title: item.title,
              subtitle: item.subtitle,
              isCircular: item.type == LibraryItemType.artist,
              onTap: () {},
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...LibrarySort.values.map((sort) {
                return ListTile(
                  title: Text(sort.label),
                  trailing: _sortBy == sort 
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = sort;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  List<LibraryItem> _getLibraryItems() {
    // Mock data
    return [
      LibraryItem(
        title: 'Liked Songs',
        subtitle: 'Playlist • 234 songs',
        imageUrl: '',
        type: LibraryItemType.playlist,
        isPinned: true,
      ),
      LibraryItem(
        title: 'The Weeknd',
        subtitle: 'Artist',
        imageUrl: '',
        type: LibraryItemType.artist,
      ),
      LibraryItem(
        title: 'After Hours',
        subtitle: 'Album • The Weeknd',
        imageUrl: '',
        type: LibraryItemType.album,
      ),
      LibraryItem(
        title: 'Chill Vibes',
        subtitle: 'Playlist • 56 songs',
        imageUrl: '',
        type: LibraryItemType.playlist,
      ),
      LibraryItem(
        title: 'Drake',
        subtitle: 'Artist',
        imageUrl: '',
        type: LibraryItemType.artist,
      ),
      LibraryItem(
        title: 'Focus Flow',
        subtitle: 'Playlist • 120 songs',
        imageUrl: '',
        type: LibraryItemType.playlist,
      ),
      LibraryItem(
        title: 'Scorpion',
        subtitle: 'Album • Drake',
        imageUrl: '',
        type: LibraryItemType.album,
      ),
    ];
  }
}

enum LibraryFilter {
  all('All'),
  playlists('Playlists'),
  artists('Artists'),
  albums('Albums');

  const LibraryFilter(this.label);
  final String label;
}

enum LibrarySort {
  recent('Recents'),
  recentlyAdded('Recently Added'),
  alphabetical('Alphabetical'),
  creator('Creator');

  const LibrarySort(this.label);
  final String label;
}

enum LibraryItemType { playlist, artist, album }

class LibraryItem {
  const LibraryItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.type,
    this.isPinned = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final LibraryItemType type;
  final bool isPinned;
}

class _LibraryListItem extends StatelessWidget {
  const _LibraryListItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.isCircular = false,
    this.isPinned = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isCircular;
  final bool isPinned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: isCircular 
              ? BorderRadius.circular(28) 
              : BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
      title: Row(
        children: [
          if (isPinned) ...[
            Icon(
              Icons.push_pin_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}
