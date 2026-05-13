import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/public_dashboard_service.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../widgets/featured_carousel.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/featured_youtube_channels_section.dart';

/// Public Landing Screen
///
/// Shown to unauthenticated web users. Displays the same dashboard
/// layout as HomeScreen but uses the public API (no auth).
/// All play actions show a "Login to Play" dialog.
class PublicLandingScreen extends StatefulWidget {
  final VoidCallback onSignIn;

  const PublicLandingScreen({super.key, required this.onSignIn});

  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<PublicDashboardService>();
      await service.fetchPublicDashboard();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Show "Login to Play" dialog when user tries to play a song
  void _showLoginPrompt() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Dialog(
            backgroundColor: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Sign In to Play',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Create a free account to start listening to your favorite music and videos.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onSignIn();
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign In with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Intercepts play and shows login prompt instead
  void _onPlayAttempt(List<MediaItem> items, int index) {
    _showLoginPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<PublicDashboardService>(
        builder: (context, dashboard, child) {
          final latestReleases = dashboard.latestReleases;
          final popularTracks = dashboard.popularTracks;

          // Audio and video come from dedicated API calls (no client-side filtering)
          final videos = dashboard.videos;
          final audios = dashboard.audios;
          final hasVisibleContent =
              latestReleases.isNotEmpty ||
              popularTracks.isNotEmpty ||
              videos.isNotEmpty ||
              audios.isNotEmpty;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // App Bar with Sign In button
                _buildAppBar(theme, isDark),

                // Loading State
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else ...[
                  // Hero Carousel
                  _buildHeroCarousel(latestReleases),

                  // Welcome Banner
                  _buildWelcomeBanner(theme, isDark),

                  // Latest Releases
                  if (latestReleases.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Latest Releases',
                      icon: Icons.new_releases_rounded,
                      items: latestReleases,
                      showBadge: true,
                    ),

                  // Popular/Trending
                  if (popularTracks.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Trending Now',
                      icon: Icons.trending_up_rounded,
                      items: popularTracks,
                    ),

                  // Videos Grid
                  if (videos.isNotEmpty)
                    _buildGridSection(
                      context,
                      title: 'Videos',
                      icon: Icons.play_circle_filled_rounded,
                      items: videos,
                    ),

                  // Audio List
                  if (audios.isNotEmpty)
                    _buildListSection(
                      context,
                      title: 'Audio',
                      icon: Icons.music_note_rounded,
                      items: audios,
                    ),

                  const FeaturedYoutubeChannelsSection(),

                  // Empty state
                  if (!hasVisibleContent) _buildEmptyState(),
                ],

                // Footer
                const SliverToBoxAdapter(child: AppFooter()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: isDark
          ? AppColors.darkBg.withOpacity(0.95)
          : AppColors.lightBg.withOpacity(0.95),
      elevation: 0,
      title: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo_light.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Veena',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        // Sign In Button
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.screenPadding),
          child: ElevatedButton.icon(
            onPressed: widget.onSignIn,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Sign In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCarousel(List<MediaItem> items) {
    final featuredItems = items.take(5).toList();

    if (featuredItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FeaturedCarousel(items: featuredItems, onPlay: _onPlayAttempt),
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Veena 🎵',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to play songs, create playlists, and explore your music library.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: widget.onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
    bool showBadge = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.sm,
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length > 10 ? 10 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 140,
                  child: AuraAlbumCard(
                    title: item.title,
                    subtitle: item.artistName,
                    imageUrl: item.thumbnailUrl ?? '',
                    mediaType: item.mediaType,
                    isNew: showBadge && index < 3,
                    onTap: () => _onPlayAttempt(items, index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildGridSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: SectionHeader(title: title),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length > 6 ? 6 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AuraAlbumCard(
                title: item.title,
                subtitle: item.artistName,
                imageUrl: item.thumbnailUrl ?? '',
                mediaType: item.mediaType,
                onTap: () => _onPlayAttempt(items, index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MediaItem> items,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: SectionHeader(title: title),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            itemCount: items.length > 5 ? 5 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AuraTrackTile(
                  title: item.title,
                  subtitle: item.artistName,
                  imageUrl: item.thumbnailUrl,
                  playedCount: item.playedCount > 0 ? item.playedCount : null,
                  likeCount: item.likeCount > 0 ? item.likeCount : null,
                  onTap: () => _onPlayAttempt(items, index),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No content available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for new music!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
