import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../auth/services/auth_service.dart';

/// Home Screen - Dynamic Studio One Layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load dashboard data on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      context.read<DashboardProvider>().loadDashboard(
        token: authService.token,
      );
    });

    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final authService = context.read<AuthService>();
      context.read<DashboardProvider>().loadMorePopularTracks(
        token: authService.token,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardProvider = context.watch<DashboardProvider>();
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => dashboardProvider.loadDashboard(token: authService.token),
        child: CustomScrollView(
          controller: _scrollController,
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
                          _getGreeting(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          authService.userName ?? 'User',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: authService.userPicture != null 
                          ? NetworkImage(authService.userPicture!) 
                          : null,
                      child: authService.userPicture == null 
                          ? const Icon(Icons.person) 
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    
            if (dashboardProvider.state == DashboardState.loading && dashboardProvider.data == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashboardProvider.state == DashboardState.error)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${dashboardProvider.errorMessage}'),
                      ElevatedButton(
                        onPressed: () => dashboardProvider.loadDashboard(token: authService.token),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Latest Releases
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Latest releases',
                  actionLabel: 'See all',
                  onActionTap: () {},
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: dashboardProvider.latestReleases.isEmpty 
                    ? _buildEmptyState('No new releases')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.md,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: dashboardProvider.latestReleases.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = dashboardProvider.latestReleases[index];
                          return SizedBox(
                            width: 160,
                            child: AuraAlbumCard(
                              title: item.title,
                              subtitle: item.artistName,
                              imageUrl: item.thumbnailUrl ?? 'https://picsum.photos/300?random=$index',
                              isNew: index == 0,
                              onTap: () {
                                context.read<PlaybackProvider>().setQueue(
                                  dashboardProvider.latestReleases,
                                  initialStateIndex: index,
                                );
                              },
                            ),
                          );
                        },
                      ),
                ),
              ),
    
              // Recommended Artists Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: SectionHeader(title: 'Recommended Artists'),
                ),
              ),
    
              // Artists Grid (Mocked from dynamic data)
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenPadding,
                  right: AppSpacing.screenPadding,
                  top: AppSpacing.md,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final artists = dashboardProvider.data?.recommendedArtists ?? [];
                      if (artists.isEmpty) return const SizedBox();
                      final artist = artists[index % artists.length];
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage('https://picsum.photos/200?random=${index+50}'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist['name'] ?? 'Artist',
                            style: theme.textTheme.labelLarge,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                    childCount: (dashboardProvider.data?.recommendedArtists.length ?? 0).clamp(0, 4),
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
                      final item = dashboardProvider.popularTracks[index];
                      final isPlaying = context.watch<PlaybackProvider>().currentMedia?.id == item.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AuraTrackTile(
                          title: item.title,
                          subtitle: '${item.artistName} • ${item.mediaType}',
                          imageUrl: item.thumbnailUrl ?? 'https://picsum.photos/100?random=${index + 20}',
                          duration: '3:45',
                          isPlaying: isPlaying,
                          onTap: () {
                            context.read<PlaybackProvider>().setQueue(
                              dashboardProvider.popularTracks,
                              initialStateIndex: index,
                            );
                          },
                        ),
                      );
                    },
                    childCount: dashboardProvider.popularTracks.length,
                  ),
                ),
              ),

              // Loading indicator for infinite scroll
              if (dashboardProvider.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // End of list indicator
              if (!dashboardProvider.hasMoreTracks && dashboardProvider.popularTracks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'No more tracks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            
            // Bottom padding for floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
