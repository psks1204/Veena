import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/library_provider.dart';
import '../../../../core/providers/playback_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/aura_cards.dart';

/// Library Screen - Aura Design
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _currentFilter = LibraryFilter.all;
  
  // Hardcoded grid view for "Albums List" style as per wireframe request, 
  // but keeping toggle capability logic if needed, defaulting to true for the visual.
  final bool _isGridView = true; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final libraryProvider = context.watch<LibraryProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar Area
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Your Library',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.search, size: 28),
                  ),
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.add_rounded, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // Filters
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
                      backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Grid Content
          if (libraryProvider.state == LibraryState.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (libraryProvider.state == LibraryState.error)
            SliverFillRemaining(
              child: Center(child: Text('Error: ${libraryProvider.errorMessage}')),
            )
          else if (libraryProvider.history.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No history yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = libraryProvider.history[index];
                    return AuraAlbumCard(
                      title: item.title,
                      subtitle: item.artistName,
                      imageUrl: item.thumbnailUrl ?? 'https://picsum.photos/300?random=$index',
                      onTap: () {
                        context.read<PlaybackProvider>().playMedia(item);
                      },
                    );
                  },
                  childCount: libraryProvider.history.length,
                ),
              ),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  List<LibraryItem> _getMockItems() {
    return List.generate(10, (index) => LibraryItem(
       title: 'Album ${index + 1}',
       subtitle: 'Artist Name',
       imageUrl: 'https://picsum.photos/300?random=${index + 50}',
       type: LibraryItemType.album,
    ));
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

