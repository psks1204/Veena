import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../../shared/widgets/aura_cards.dart';

/// Callback to fetch items for a specific page
typedef FetchItemsCallback = Future<List<MediaItem>> Function(int page, int limit);

/// Paginated Section Screen
/// 
/// Displays a list of media items with infinite scrolling.
/// Used for "See All" sections to load content progressively.
class PaginatedSectionScreen extends StatefulWidget {
  final String title;
  final FetchItemsCallback fetchItems;
  final int pageSize;

  const PaginatedSectionScreen({
    super.key,
    required this.title,
    required this.fetchItems,
    this.pageSize = 20,
  });

  @override
  State<PaginatedSectionScreen> createState() => _PaginatedSectionScreenState();
}

class _PaginatedSectionScreenState extends State<PaginatedSectionScreen> {
  final List<MediaItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchItems(_currentPage, widget.pageSize);
      
      if (!mounted) return;

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _isLoading = false;
        if (newItems.length < widget.pageSize) {
          _hasMore = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _playAll(BuildContext context, {bool shuffle = false}) {
    final player = context.read<PlayerProvider>();
    player.playQueue(_items, shuffle: shuffle);
  }

  void _playMedia(BuildContext context, MediaItem item, int index) {
    final player = context.read<PlayerProvider>();
    player.playQueue(_items, startIndex: index);

    if (item.isVideo) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(0.6),
                      colorScheme.primary.withOpacity(0.3),
                      isDark ? AppColors.darkBg : AppColors.lightBg,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (_items.isNotEmpty) ...[
                IconButton(
                  onPressed: () => _playAll(context, shuffle: true),
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: 'Shuffle',
                ),
                IconButton(
                  onPressed: () => _playAll(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: 'Play All',
                ),
              ],
            ],
          ),

          // Error State
          if (_error != null && _items.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Failed to load items', style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: _loadMore,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty && !_isLoading)
             SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            // Items List
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _items.length) {
                      // Bottom loading indicator
                      return _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const SizedBox(height: 80); // Bottom padding
                    }

                    final item = _items[index];
                    final player = context.watch<PlayerProvider>();
                    final isPlaying = player.currentMedia?.id == item.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AuraTrackTile(
                        title: item.title,
                        subtitle: item.artistName,
                        imageUrl: item.thumbnailUrl,
                        isPlaying: isPlaying,
                        onTap: () => _playMedia(context, item, index),
                        onLikeTap: () {}, // Handled internally by tile or service if needed
                        onMoreTap: () {
                           showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddToPlaylistSheet(mediaItem: item),
                           );
                        },
                      ),
                    );
                  },
                  childCount: _items.length + 1, // +1 for loading indicator/padding
                ),
              ),
            ),
        ],
      ),
    );
  }
}
