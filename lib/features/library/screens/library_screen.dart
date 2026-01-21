import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                   final item = _getMockItems()[index];
                   return AuraAlbumCard(
                     title: item.title,
                     subtitle: item.subtitle,
                     imageUrl: item.imageUrl, // In real app, handling item type
                     onTap: () {
                         // Mock navigation to detail
                         // context.push('/album/1');
                     },
                   );
                 },
                 childCount: _getMockItems().length,
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

