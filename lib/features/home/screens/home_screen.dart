import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/video_player_screen.dart';

/// Home Screen - Studio One Layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MediaItem> _mediaItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  Future<void> _loadMedia() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final mediaService = context.read<MediaService>();
      final response = await mediaService.fetchMedia(size: 20);
      
      setState(() {
        _mediaItems = response.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playMedia(MediaItem item) {
    final player = context.read<PlayerProvider>();
    player.play(item);

    // For VIDEO, navigate to full-screen player
    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const VideoPlayerScreen(),
        ),
      );
    }
    // For AUDIO, just play (mini player will show)
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Split media by type
    final videos = _mediaItems.where((m) => m.isVideo).toList();
    final audios = _mediaItems.where((m) => m.isAudio).toList();
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMedia,
        child: CustomScrollView(
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
                           '${_getGreeting()},',
                           style: theme.textTheme.bodyMedium?.copyWith(
                             color: theme.colorScheme.onSurface.withOpacity(0.6),
                           ),
                         ),
                         Text(
                           'Welcome',
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

            // Loading State
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load content'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadMedia,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Latest Releases (All Media)
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Latest Releases',
                  actionLabel: 'See all',
                  onActionTap: () {},
                ),
              ),
              SliverToBoxAdapter(
                 child: SizedBox(
                   height: 220,
                   child: _mediaItems.isEmpty
                     ? const Center(child: Text('No content available'))
                     : ListView.separated(
                         padding: const EdgeInsets.symmetric(
                           horizontal: AppSpacing.screenPadding,
                           vertical: AppSpacing.md,
                         ),
                         scrollDirection: Axis.horizontal,
                         itemCount: _mediaItems.length > 10 ? 10 : _mediaItems.length,
                         separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                         itemBuilder: (context, index) {
                            final item = _mediaItems[index];
                            return SizedBox(
                              width: 160,
                              child: AuraAlbumCard(
                                title: item.title,
                                subtitle: item.description ?? '',
                                imageUrl: item.thumbnailUrl ?? '',
                                mediaType: item.mediaType,
                                isNew: index == 0,
                                onTap: () => _playMedia(item),
                              ),
                            );
                         },
                       ),
                 ),
              ),

              // Videos Section
              if (videos.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: SectionHeader(
                      title: 'Videos',
                      actionLabel: 'See all',
                      onActionTap: () {},
                    ),
                  ),
                ),
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
                       childAspectRatio: 0.8,
                     ),
                     delegate: SliverChildBuilderDelegate(
                       (context, index) {
                         final item = videos[index];
                         return AuraAlbumCard(
                            title: item.title,
                            subtitle: item.description ?? '',
                            imageUrl: item.thumbnailUrl ?? '',
                            mediaType: item.mediaType,
                            onTap: () => _playMedia(item),
                         );
                       },
                       childCount: videos.length > 6 ? 6 : videos.length,
                     ),
                  ),
                ),
              ],

              // Audio Section
              if (audios.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: SectionHeader(
                      title: 'Audio',
                      actionLabel: 'See all',
                      onActionTap: () {},
                    ),
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
                         final item = audios[index];
                         final player = context.watch<PlayerProvider>();
                         final isPlaying = player.currentMedia?.id == item.id;
                         
                         return Padding(
                           padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                           child: AuraTrackTile(
                             title: item.title,
                             subtitle: item.description ?? '',
                             imageUrl: item.thumbnailUrl,
                             isPlaying: isPlaying,
                             onTap: () => _playMedia(item),
                           ),
                         );
                       },
                       childCount: audios.length > 6 ? 6 : audios.length,
                     ),
                  ),
                ),
              ],

              // All Content Grid (if no specific sections)
              if (videos.isEmpty && audios.isEmpty && _mediaItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: SectionHeader(title: 'All Content'),
                  ),
                ),
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
                       childAspectRatio: 0.8,
                     ),
                     delegate: SliverChildBuilderDelegate(
                       (context, index) {
                         final item = _mediaItems[index];
                         return AuraAlbumCard(
                            title: item.title,
                            subtitle: item.description ?? '',
                            imageUrl: item.thumbnailUrl ?? '',
                            mediaType: item.mediaType,
                            onTap: () => _playMedia(item),
                         );
                       },
                       childCount: _mediaItems.length,
                     ),
                  ),
                ),
              ],
            ],
            
            // Bottom padding for floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }
}

