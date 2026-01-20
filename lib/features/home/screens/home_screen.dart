import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/artwork_card.dart';
import '../../../shared/widgets/section_header.dart';

/// Home Screen
/// 
/// Featured playlists, recommendations, and recently played.
/// Typography-driven with confident visual hierarchy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              'Good evening',
              style: theme.textTheme.headlineMedium,
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.history_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),

          // Quick access grid
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 3.5,
              ),
              delegate: SliverChildListDelegate([
                _QuickAccessCard(
                  title: 'Liked Songs',
                  imageUrl: '',
                  onTap: () {},
                ),
                _QuickAccessCard(
                  title: 'Chill Vibes',
                  imageUrl: '',
                  onTap: () {},
                ),
                _QuickAccessCard(
                  title: 'Daily Mix 1',
                  imageUrl: '',
                  onTap: () {},
                ),
                _QuickAccessCard(
                  title: 'Discover Weekly',
                  imageUrl: '',
                  onTap: () {},
                ),
                _QuickAccessCard(
                  title: 'Focus Flow',
                  imageUrl: '',
                  onTap: () {},
                ),
                _QuickAccessCard(
                  title: 'Your Top 2024',
                  imageUrl: '',
                  onTap: () {},
                ),
              ]),
            ),
          ),

          // Made for you section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: SectionHeader(
                title: 'Made for you',
                actionLabel: 'See all',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final playlists = [
                    ('Daily Mix ${index + 1}', 'Your personalized mix'),
                    ('Discover Weekly', 'New music picked for you'),
                    ('Release Radar', 'Fresh releases from artists you follow'),
                    ('Time Capsule', 'Songs you loved years ago'),
                    ('Repeat Rewind', 'Your past favorites'),
                    ('On Repeat', 'Songs you can\'t stop playing'),
                  ];
                  return ArtworkCard(
                    imageUrl: '',
                    title: playlists[index].$1,
                    subtitle: playlists[index].$2,
                    size: ArtworkCardSize.medium,
                    showPlayButton: true,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),

          // Recently played section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: SectionHeader(
                title: 'Recently played',
                actionLabel: 'See all',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final items = [
                    ('Starboy', 'The Weeknd'),
                    ('Blinding Lights', 'The Weeknd'),
                    ('One Dance', 'Drake'),
                    ('Shape of You', 'Ed Sheeran'),
                    ('Thinking Out Loud', 'Ed Sheeran'),
                    ('Uptown Funk', 'Bruno Mars'),
                  ];
                  return ArtworkCard(
                    imageUrl: '',
                    title: items[index].$1,
                    subtitle: items[index].$2,
                    size: ArtworkCardSize.medium,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),

          // Popular artists section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: SectionHeader(
                title: 'Popular artists',
                actionLabel: 'See all',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final artists = [
                    'The Weeknd',
                    'Drake',
                    'Ed Sheeran',
                    'Taylor Swift',
                    'Billie Eilish',
                    'Bruno Mars',
                  ];
                  return ArtworkCard(
                    imageUrl: '',
                    title: artists[index],
                    subtitle: 'Artist',
                    size: ArtworkCardSize.small,
                    isCircular: true,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),

          // Bottom padding for mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}

/// Quick access card for top grid
class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Row(
          children: [
            // Artwork
            Container(
              width: 56,
              height: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
