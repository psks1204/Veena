import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../player/screens/unified_player_screen.dart';

/// Dedicated Karaoke Screen
///
/// Displays all available karaoke tracks for users to sing along and record covers.
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  final TextEditingController _searchController = TextEditingController();
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

    final allKaraoke = dashboard.karaoke;
    final filteredKaraoke = _searchQuery.isEmpty
        ? allKaraoke
        : allKaraoke.where((track) {
            final title = track.title.toLowerCase();
            final artist = track.artistName.toLowerCase();
            return title.contains(_searchQuery) || artist.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => dashboard.fetchKaraoke(notify: true),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
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
                                'Karaoke',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sing along and record your favorite covers',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
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
                                  onPressed: () =>
                                      mediaService.toggleLike(track.id, initial: track.liked),
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}
