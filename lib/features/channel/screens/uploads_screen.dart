import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/media_item.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../player/screens/unified_player_screen.dart';
import '../models/channel.dart' as channel_models;
import '../services/channel_service.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<channel_models.UserMediaResponse> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _statusFilter;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadMore(refresh: true);
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

  Future<void> _loadMore({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _items.clear();
        _hasMore = true;
        _page = 0;
      }
    });

    try {
      final result = await context.read<ChannelService>().getMyMedia(
        approvalStatus: _statusFilter,
        page: _page,
      );

      if (!mounted) return;
      setState(() {
        _items.addAll(result.content);
        _hasMore = !result.isLast;
        _page++;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load uploads')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    _loadMore(refresh: true);
  }

  void _playItem(channel_models.UserMediaResponse item) {
    final playable = _items
        .where((e) => e.hlsUrl != null && e.hlsUrl!.isNotEmpty)
        .map(_toMediaItem)
        .toList();
    final selected = _toMediaItem(item);
    final index = playable.indexWhere((m) => m.id == selected.id);

    if (index == -1) {
      return;
    }

    final player = context.read<PlayerProvider>();
    player.playQueue(playable, startIndex: index);

    if (selected.isVideo) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()));
    }
  }

  MediaItem _toMediaItem(channel_models.UserMediaResponse item) {
    final mediaType = item.mediaType == channel_models.MediaType.video
        ? MediaType.video
        : MediaType.audio;

    final status = item.status == channel_models.MediaStatus.ready
        ? MediaStatus.published
        : MediaStatus.processing;

    return MediaItem(
      id: item.id,
      title: item.title,
      description: item.description,
      mediaType: mediaType,
      status: status,
      hlsUrl: item.hlsUrl,
      thumbnailUrl: item.thumbnailUrl,
      createdAt: item.createdAt ?? DateTime.now(),
      updatedAt: item.updatedAt ?? DateTime.now(),
      playedCount: item.playCount,
      artist: ArtistInfo(
        id: 0,
        name: (item.uploadedByName ?? item.channelName ?? 'Veena Creator')
            .trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.brightness == Brightness.dark
                ? AppColors.darkBg
                : AppColors.lightBg,
            title: Text(
              'Uploads',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'APPROVED'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'PENDING'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'REJECTED'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_items.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No uploads found yet')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: 140,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  final item = _items[index];
                  final media = _toMediaItem(item);
                  final isPlaying =
                      context.watch<PlayerProvider>().currentMedia?.id ==
                      item.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AuraTrackTile(
                      title: media.title,
                      subtitle: media.artistName,
                      imageUrl: media.thumbnailUrl,
                      isPlaying: isPlaying,
                      onTap: () => _playItem(item),
                      onMoreTap: () {
                        MediaOptionsSheet.show(context, mediaItem: media);
                      },
                    ),
                  );
                }, childCount: _items.length + 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _applyFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
