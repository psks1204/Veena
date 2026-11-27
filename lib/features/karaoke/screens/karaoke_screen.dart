import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../competition/services/competition_service.dart';
import '../../competition/widgets/competition_view.dart';
import '../../player/screens/unified_player_screen.dart';

/// Dedicated Karaoke Screen
///
/// Features two main sections:
/// 1. "All Songs": Where all available karaoke tracks are shown to sing and record.
/// 2. "Competition": Where users see ongoing singing competitions, banners,
///    prizes, live ranking/podium, and winner announcements.
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSection = 0; // 0: All Songs, 1: Competition
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKaraoke();
      context.read<CompetitionService>().fetchOngoingCompetition();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKaraoke() async {
    final dashboard = context.read<DashboardService>();
    if (dashboard.karaoke.isEmpty) {
      setState(() => _isLoading = true);
      try {
        await dashboard.fetchKaraoke(notify: true);
      } catch (e) {
        debugPrint('[KaraokeScreen] Error loading karaoke: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  bool _loadMoreScheduled = false;

  /// Ask for the next page after this frame — loading notifies listeners,
  /// which can't happen while the list is still building.
  void _scheduleLoadMore(DashboardService dashboard) {
    // The tab stays alive while hidden and still rebuilds when a page lands;
    // only fetch while it's on screen (AppShell turns tickers off otherwise).
    if (!TickerMode.of(context)) return;
    if (_loadMoreScheduled ||
        !dashboard.hasMoreKaraoke ||
        dashboard.isLoadingMoreKaraoke ||
        dashboard.karaokeLoadMoreFailed) {
      return;
    }
    _loadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreScheduled = false;
      if (!mounted) return;
      context.read<DashboardService>().loadMoreKaraoke();
    });
  }

  void _playKaraokeTrack(List<MediaItem> allTracks, int index) {
    final player = context.read<PlayerProvider>();
    player.playQueue(allTracks, startIndex: index);

    final track = allTracks[index];
    if (track.isVideo && !kIsWeb) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboard = context.watch<DashboardService>();
    final mediaService = context.watch<MediaService>();
    final player = context.watch<PlayerProvider>();
    final compService = context.watch<CompetitionService>();

    final allKaraoke = dashboard.karaoke;
    final filteredKaraoke = _searchQuery.isEmpty
        ? allKaraoke
        : allKaraoke.where((track) {
            final title = track.title.toLowerCase();
            final artist = track.artistName.toLowerCase();
            return title.contains(_searchQuery) || artist.contains(_searchQuery);
          }).toList();

    // Search runs over the songs loaded so far, so while a query is active
    // keep pulling in the remaining pages until the whole catalogue is in.
    if (_searchQuery.isNotEmpty && _selectedSection == 0) {
      _scheduleLoadMore(dashboard);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & Segmented Pill Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Karaoke Arena',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sing along, record covers & win prizes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tabs: [ 🎤 All Songs ] [ 🏆 Competition ]
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            title: 'All Songs',
                            icon: Icons.queue_music_rounded,
                            isSelected: _selectedSection == 0,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSection = 0);
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildSegmentButton(
                            title: 'Competition',
                            icon: Icons.emoji_events_rounded,
                            isSelected: _selectedSection == 1,
                            isDark: isDark,
                            badge: compService.currentCompetition?.isOngoing == true
                                ? 'LIVE'
                                : null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSection = 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content: Tab 0 (All Songs) or Tab 1 (Competition View)
            Expanded(
              child: _selectedSection == 0
                  ? _buildSongsSection(
                      context: context,
                      filteredKaraoke: filteredKaraoke,
                      allKaraoke: allKaraoke,
                      isDark: isDark,
                      player: player,
                      mediaService: mediaService,
                      compService: compService,
                      dashboard: dashboard,
                    )
                  : CompetitionView(
                      onSingNowTap: () => setState(() => _selectedSection = 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongsSection({
    required BuildContext context,
    required List<MediaItem> filteredKaraoke,
    required List<MediaItem> allKaraoke,
    required bool isDark,
    required PlayerProvider player,
    required MediaService mediaService,
    required CompetitionService compService,
    required DashboardService dashboard,
  }) {
    final ongoingComp = compService.currentCompetition;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await dashboard.fetchKaraoke(notify: true);
        await compService.fetchOngoingCompetition(forceRefresh: true);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Competition Teaser Banner (if ongoing)
                  if (ongoingComp != null && ongoingComp.isOngoing) ...[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSection = 1);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF331422), const Color(0xFF1E1420)]
                                : [const Color(0xFFFDE8F1), const Color(0xFFFEEFF6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Competition Live!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      if (ongoingComp.daysRemaining > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${ongoingComp.daysRemaining}d left)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    ongoingComp.prize != null
                                        ? 'Sing & win: ${ongoingComp.prize}'
                                        : 'Sing your cover and climb the leaderboard',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search karaoke songs...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Content List
          if (_isLoading && allKaraoke.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (filteredKaraoke.isEmpty &&
              _searchQuery.isNotEmpty &&
              (dashboard.hasMoreKaraoke || dashboard.isLoadingMoreKaraoke) &&
              !dashboard.karaokeLoadMoreFailed)
            // No match yet, but there are songs we haven't fetched.
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Searching all karaoke songs...',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredKaraoke.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic_off_rounded,
                      size: 56,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No karaoke songs matching "$_searchQuery"'
                          : 'No karaoke songs available yet',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Nearing the end of what's loaded: fetch the next page.
                    if (index >= filteredKaraoke.length - 5) {
                      _scheduleLoadMore(dashboard);
                    }
                    final track = filteredKaraoke[index];
                    final isPlaying =
                        player.currentMedia?.id == track.id && player.isPlaying;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? (isPlaying
                                ? AppColors.primary.withOpacity(0.12)
                                : Colors.white.withOpacity(0.04))
                            : (isPlaying
                                ? AppColors.primary.withOpacity(0.08)
                                : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(12),
                        border: isPlaying
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.4),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (track.thumbnailUrl != null &&
                                    track.thumbnailUrl!.isNotEmpty)
                                  AppNetworkImage(
                                    imageUrl: track.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 150,
                                  )
                                else
                                  Container(
                                    color: isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[300],
                                    child: const Icon(
                                      Icons.mic_rounded,
                                      size: 24,
                                    ),
                                  ),
                                if (isPlaying)
                                  Container(
                                    color: Colors.black45,
                                    child: const Center(
                                      child: Icon(
                                        Icons.graphic_eq_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isPlaying
                                ? AppColors.primary
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'KARAOKE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                track.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                mediaService.isLiked(
                                  track.id,
                                  initial: track.liked,
                                )
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: mediaService.isLiked(
                                  track.id,
                                  initial: track.liked,
                                )
                                    ? AppColors.primary
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                              onPressed: () => mediaService.toggleLike(
                                track.id,
                                initial: track.liked,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              onPressed: () {
                                MediaOptionsSheet.show(context, mediaItem: track);
                              },
                            ),
                          ],
                        ),
                        onTap: () => _playKaraokeTrack(filteredKaraoke, index),
                      ),
                    );
                  },
                  childCount: filteredKaraoke.length,
                ),
              ),
            ),
          if (filteredKaraoke.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildLoadMoreFooter(dashboard, isDark),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  /// Spinner while the next page loads, or a retry button if it failed.
  Widget _buildLoadMoreFooter(DashboardService dashboard, bool isDark) {
    if (dashboard.isLoadingMoreKaraoke) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    if (dashboard.karaokeLoadMoreFailed && dashboard.hasMoreKaraoke) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton.icon(
            onPressed: dashboard.loadMoreKaraoke,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Couldn't load more songs. Retry"),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
