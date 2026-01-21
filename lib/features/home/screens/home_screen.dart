import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';

/// Home Screen - Studio One Layout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar Area
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                         'Good Evening,',
                         style: theme.textTheme.bodyMedium?.copyWith(
                           color: theme.colorScheme.onSurface.withOpacity(0.6),
                         ),
                       ),
                       Text(
                         'Kai',
                         style: theme.textTheme.headlineMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.person),
                  ),
                ],
              ),
            ),
          ),

          // Latest Releases (Horizontal Scroll)
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Latest releases',
              actionLabel: 'See all',
              onActionTap: () {},
            ),
          ),
          SliverToBoxAdapter(
             child: SizedBox(
               height: 220, // Adjusted for Aura Album Card
               child: ListView.separated(
                 padding: const EdgeInsets.symmetric(
                   horizontal: AppSpacing.screenPadding,
                   vertical: AppSpacing.md,
                 ),
                 scrollDirection: Axis.horizontal,
                 itemCount: 5,
                 separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                 itemBuilder: (context, index) {
                    final titles = ['Midnight Rain', 'Solar Power', 'After Hours', 'Future Nostalgia', 'Planet Her'];
                    final artists = ['Taylor Swift', 'Lorde', 'The Weeknd', 'Dua Lipa', 'Doja Cat'];
                    return SizedBox(
                      width: 160,
                      child: AuraAlbumCard(
                        title: titles[index],
                        subtitle: artists[index],
                        imageUrl: 'https://picsum.photos/300?random=$index',
                        isNew: index == 0,
                        onTap: () {},
                      ),
                    );
                 },
               ),
             ),
          ),

          // Studio Albums Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: SectionHeader(title: 'Studio Albums'),
            ),
          ),

          // Studio Albums Grid
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.md,
            ),
            sliver: SliverGrid(
               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                 maxCrossAxisExtent: 200,
                 mainAxisSpacing: AppSpacing.md,
                 crossAxisSpacing: AppSpacing.md,
                 childAspectRatio: 0.8, // Taller for title/subtitle
               ),
               delegate: SliverChildBuilderDelegate(
                 (context, index) {
                   return AuraAlbumCard(
                      title: 'Album ${index + 1}',
                      subtitle: 'Artist Name',
                      imageUrl: 'https://picsum.photos/300?random=${index + 10}',
                      onTap: () {},
                   );
                 },
                 childCount: 4,
               ),
            ),
          ),

          // Popular Tracks
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: SectionHeader(title: 'Popular Tracks'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.md,
            ),
             sliver: SliverList(
               delegate: SliverChildBuilderDelegate(
                 (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AuraTrackTile(
                        title: 'Track Title ${index + 1}',
                        subtitle: 'Artist Name • Album',
                        imageUrl: 'https://picsum.photos/100?random=${index + 20}',
                        duration: '3:45',
                        isPlaying: index == 0, // Mock playing state
                        onTap: () {},
                      ),
                    );
                 },
                 childCount: 6,
               ),
             ),
          ),
          
          // Bottom padding for floating nav
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}
