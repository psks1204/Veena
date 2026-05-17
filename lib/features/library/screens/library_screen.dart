import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/media_download_models.dart';
import '../../../core/models/artist.dart';
import '../../../core/services/library_service.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/subscription_modal.dart';
import '../../auth/services/auth_service.dart';
import '../../player/screens/unified_player_screen.dart';
import 'playlist_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'album_detail_screen.dart';

/// Library Screen - Spotify-like Premium Design
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'Playlists'; // Default to Playlists
  final List<String> _filters = [
    'Playlists',
    'Artists',
    'Albums',
    'Favorites',
    'Downloads',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibrary();
    });
  }

  Future<void> _loadLibrary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await context.read<LibraryService>().fetchLibrary();
    } catch (e) {
      debugPrint('Error loading library: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Create Playlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Playlist name',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await context.read<LibraryService>().createPlaylist(
                  nameController.text,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final profileProvider = context.watch<ProfileProvider>();
                      final authService = context.watch<AuthService>();
                      final profile = profileProvider.profile;

                      // Fallback logic for photo
                      final pPhoto = profile?.photoUrl;
                      final userPicture = (pPhoto != null && pPhoto.isNotEmpty)
                          ? pPhoto
                          : authService.userPicture;

                      // Fallback logic for initials
                      String userInitials = 'U';
                      final pName = profile?.name;
                      final userName = (pName != null && pName.isNotEmpty)
                          ? pName
                          : (authService.userName ?? 'User');

                      if (userName != 'User') {
                        final parts = userName.split(' ');
                        if (parts.length >= 2) {
                          userInitials = '${parts[0][0]}${parts[1][0]}'
                              .toUpperCase();
                        } else if (userName.isNotEmpty) {
                          userInitials = userName[0].toUpperCase();
                        }
                      } else if (profile?.initials != null) {
                        userInitials = profile!.initials;
                      } else if (authService.userInitials.isNotEmpty) {
                        userInitials = authService.userInitials;
                      }

                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            userPicture != null && userPicture.isNotEmpty
                            ? NetworkImage(userPicture)
                            : null,
                        child: (userPicture == null || userPicture.isEmpty)
                            ? Text(
                                userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Library',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, size: 28),
                  ),
                  IconButton(
                    onPressed: _showCreatePlaylistDialog,
                    icon: const Icon(Icons.add_rounded, size: 30),
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      final newFilter = isSelected ? 'All' : filter;
                      setState(() {
                        _selectedFilter = newFilter;
                      });

                      // Trigger fetch for followed artists when filter is selected
                      if (newFilter == 'Artists') {
                        context.read<LibraryService>().getArtists();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? Colors.white12
                                  : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Sorting & Layout bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recents',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildLibraryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryContent() {
    return Consumer<LibraryService>(
      builder: (context, library, child) {
        List<dynamic> items = [];
        bool showLikedSongsTile =
            (_selectedFilter == 'All' || _selectedFilter == 'Playlists');

        if (_selectedFilter == 'All') {
          items = [...library.playlists, ...library.artists, ...library.albums];
        } else if (_selectedFilter == 'Playlists') {
          items = library.playlists;
        } else if (_selectedFilter == 'Artists') {
          items = library.artists;
        } else if (_selectedFilter == 'Albums') {
          items = library.albums;
        } else if (_selectedFilter == 'Favorites') {
          // Use special favorites view with Play All/Shuffle
          return _buildFavoritesView(library.favorites);
        } else if (_selectedFilter == 'Downloads') {
          return _buildDownloadsView();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: 140,
          ),
          itemCount: items.length + (showLikedSongsTile ? 1 : 0),
          itemBuilder: (context, index) {
            // Liked Songs tile at the top
            if (showLikedSongsTile && index == 0) {
              return _buildLikedSongsTile(library.favorites.length);
            }

            final actualIndex = showLikedSongsTile ? index - 1 : index;
            final item = items[actualIndex];

            if (item is Playlist) {
              return _buildLibraryTile(
                title: item.name,
                subtitle: 'Playlist • ${item.description ?? 'You'}',
                imageUrl: item.coverUrl,
                isCircle: false,
                onTap: () async {
                  await AppNavigation.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: item),
                    ),
                  );
                  _loadLibrary(); // Refresh on return
                },
              );
            } else if (item is Artist) {
              return _buildLibraryTile(
                title: item.name,
                subtitle: 'Followed Artist',
                imageUrl: item.imageUrl,
                isCircle: true,
                onTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(artist: item),
                    ),
                  );
                },
              );
            } else if (item is Album) {
              return _buildLibraryTile(
                title: item.title,
                subtitle: 'Album • ${item.artistName}',
                imageUrl: item.coverUrl,
                isCircle: false,
                onTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(
                        albumId: item.id,
                        title: item.title,
                        artist: item.artistName,
                        coverUrl: item.coverUrl,
                      ),
                    ),
                  );
                },
              );
            } else if (item is MediaItem) {
              return _buildLibraryTile(
                title: item.title,
                subtitle: 'Song • ${item.description ?? ''}',
                imageUrl: item.thumbnailUrl,
                isCircle: false,
                onTap: () {
                  context.read<PlayerProvider>().play(item);
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildLikedSongsTile(int count) {
    return _buildLibraryTile(
      title: 'Liked Songs',
      subtitle: 'Playlist • $count songs',
      imageUrl: null,
      isCircle: false,
      isLikedSongs: true,
      onTap: () {
        setState(() {
          _selectedFilter = 'Favorites';
        });
      },
    );
  }

  Widget _buildLibraryTile({
    required String title,
    required String subtitle,
    String? imageUrl,
    required bool isCircle,
    required VoidCallback onTap,
    bool isLikedSongs = false,
    bool isPlaying = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isCircle ? 32 : 4),
                color: isLikedSongs
                    ? const Color(0xFF5038A0)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05)),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: isLikedSongs
                  ? const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  : (imageUrl == null || imageUrl.isEmpty
                        ? Icon(
                            isCircle
                                ? Icons.person_rounded
                                : Icons.music_note_rounded,
                            color: Colors.grey,
                          )
                        : null),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isPlaying
                          ? AppColors.primary
                          : (isLikedSongs
                                ? AppColors.primary
                                : (isDark ? Colors.white : Colors.black)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isLikedSongs)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.push_pin_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _retryDownload(String mediaId) async {
    final result = await context.read<DownloadProvider>().retryDownload(
      mediaId,
    );
    if (!mounted) return;

    final message = switch (result.status) {
      MediaDownloadStatus.success => 'Downloaded successfully',
      MediaDownloadStatus.alreadyDownloaded => 'Already downloaded',
      MediaDownloadStatus.inProgress => 'Download already in progress',
      MediaDownloadStatus.notSubscribed =>
        'Subscription is required for downloads',
      MediaDownloadStatus.unsupportedPlatform =>
        'Downloads are available on Android and iOS only',
      MediaDownloadStatus.failed =>
        result.message ?? 'Failed to retry download',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildTaskSubtitle(DownloadTaskEntry task) {
    final artist = task.media.artistName.isEmpty
        ? 'Unknown Artist'
        : task.media.artistName;
    if (task.status == DownloadTaskStatus.downloading) {
      return 'Downloading • $artist';
    }

    final error = task.errorMessage;
    if (error == null || error.isEmpty) {
      return 'Failed • $artist • Tap retry';
    }

    return 'Failed • $artist • $error';
  }

  Widget _buildDownloadTaskTile(DownloadTaskEntry task) {
    final isDownloading = task.status == DownloadTaskStatus.downloading;

    return _buildLibraryTile(
      title: task.media.title,
      subtitle: _buildTaskSubtitle(task),
      imageUrl: task.media.thumbnailUrl,
      isCircle: false,
      onTap: isDownloading ? () {} : () => _retryDownload(task.media.id),
      trailing: isDownloading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : IconButton(
              onPressed: () => _retryDownload(task.media.id),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'Retry download',
            ),
    );
  }

  Widget _buildDownloadsView() {
    return Consumer2<DownloadProvider, SubscriptionProvider>(
      builder: (context, downloadsProvider, subscription, _) {
        if (!downloadsProvider.isPlatformSupported) {
          return _buildDownloadsState(
            icon: Icons.phone_android_rounded,
            title: 'Downloads are mobile only',
            subtitle:
                'In-app downloads are currently available on Android and iOS only.',
          );
        }

        if (subscription.isLoading && !subscription.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!subscription.isNoAdsSubscribed) {
          return _buildDownloadsState(
            icon: Icons.workspace_premium_rounded,
            title: 'Subscription required',
            subtitle: 'Subscribe to use in-app offline downloads.',
            actionLabel: 'View Plans',
            onActionTap: () => showSubscriptionModal(context),
          );
        }

        if (downloadsProvider.isLoading && !downloadsProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final downloads = downloadsProvider.downloads;
        final tasks = downloadsProvider.taskEntries;

        if (downloads.isEmpty && tasks.isEmpty) {
          return _buildDownloadsState(
            icon: Icons.download_outlined,
            title: 'No downloads yet',
            subtitle:
                'Use the media options menu on any song or video to download it.',
          );
        }

        final queuedTaskIds = tasks.map((task) => task.media.id).toSet();
        final persistedDownloads = downloads
            .where((record) => !queuedTaskIds.contains(record.mediaId))
            .toList(growable: false);

        final totalItems = tasks.length + persistedDownloads.length;

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: 140,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < tasks.length) {
              final task = tasks[index];
              return _buildDownloadTaskTile(task);
            }

            final record = persistedDownloads[index - tasks.length];
            final mediaItem = MediaItem(
              id: record.mediaId,
              title: record.title,
              description: record.artistName,
              mediaType: record.mediaType,
              status: MediaStatus.published,
              visibility: MediaVisibility.public,
              hlsUrl: null,
              thumbnailUrl: record.thumbnailUrl,
              lyricsUrl: null,
              createdAt: record.downloadedAt,
              updatedAt: record.downloadedAt,
            );

            return Dismissible(
              key: ValueKey(record.mediaId),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              onDismissed: (_) async {
                final removed = await context
                    .read<DownloadProvider>()
                    .removeDownload(record.mediaId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      removed
                          ? 'Removed from downloads'
                          : 'Failed to remove download',
                    ),
                  ),
                );
              },
              child: _buildLibraryTile(
                title: record.title,
                subtitle:
                    'Downloaded • ${record.artistName.isEmpty ? 'Unknown Artist' : record.artistName} • ${_formatFileSize(record.fileSize)}',
                imageUrl: record.thumbnailUrl,
                isCircle: false,
                onTap: () {
                  context.read<PlayerProvider>().play(mediaItem);
                  if (mediaItem.isVideo) {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const UnifiedPlayerScreen(),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadsState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 52,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Build favorites view with Play All/Shuffle buttons and queue support
  Widget _buildFavoritesView(List<MediaItem> favorites) {
    final player = context.read<PlayerProvider>();

    return Column(
      children: [
        // Play All / Shuffle buttons row
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: favorites.isEmpty
                      ? null
                      : () {
                          player.playQueue(favorites);
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: favorites.isEmpty
                      ? null
                      : () {
                          player.playQueue(favorites, shuffle: true);
                        },
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Favorites list
        Expanded(
          child: Consumer<PlayerProvider>(
            builder: (context, playerWatch, _) => ListView.builder(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: 140,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                final isItemPlaying = playerWatch.currentMedia?.id == item.id;
                return _buildLibraryTile(
                  title: item.title,
                  subtitle: 'Song • ${item.description ?? item.artistName}',
                  imageUrl: item.thumbnailUrl,
                  isCircle: false,
                  isPlaying: isItemPlaying,
                  onTap: () {
                    // Play this track as part of favorites queue
                    player.playQueue(favorites, startIndex: index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
