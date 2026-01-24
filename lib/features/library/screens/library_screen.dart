import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../../shared/widgets/track_list_tile.dart';
import '../../../shared/widgets/add_to_playlist_sheet.dart';
import '../../../shared/models/media_item.dart';
import '../../../core/services/library_service.dart';
import 'playlist_detail_screen.dart';

/// Library Screen with tabs: All, Playlists, Artists, Albums, Favorites
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadLibrary();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = context.read<LibraryProvider>();
      // Refresh data when switching to specific tabs
      switch (_tabController.index) {
        case 1: // Playlists
          provider.loadPlaylists();
          break;
        case 2: // Artists
          provider.loadArtists();
          break;
        case 3: // Albums
          provider.loadAlbums();
          break;
        case 4: // Favorites
          provider.loadFavorites();
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final libraryProvider = context.watch<LibraryProvider>();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App bar Area
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Your Library',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 28),
                  ),
                  IconButton(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Artists'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Favorites'),
                ],
              ),
              isDark: isDark,
            ),
          ),
        ],
        body: libraryProvider.state == LibraryState.loading
            ? const Center(child: CircularProgressIndicator())
            : libraryProvider.state == LibraryState.error
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${libraryProvider.errorMessage}'),
                        ElevatedButton(
                          onPressed: () => libraryProvider.loadLibrary(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(libraryProvider, theme),
                      _buildPlaylistsTab(libraryProvider, theme),
                      _buildArtistsTab(libraryProvider, theme),
                      _buildAlbumsTab(libraryProvider, theme),
                      _buildFavoritesTab(libraryProvider, theme),
                    ],
                  ),
      ),
    );
  }

  // ==================== ALL TAB ====================

  Widget _buildAllTab(LibraryProvider provider, ThemeData theme) {
    final items = provider.getAllItems();

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_music_outlined,
        message: 'Your library is empty',
        subtitle: 'Start listening to add items to your library',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadLibrary(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildLibraryItemCard(item, theme, provider);
        },
      ),
    );
  }

  // ==================== PLAYLISTS TAB ====================

  Widget _buildPlaylistsTab(LibraryProvider provider, ThemeData theme) {
    final playlists = provider.playlists;

    if (playlists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music_outlined,
        message: 'No playlists yet',
        subtitle: 'Create your first playlist',
        action: ElevatedButton.icon(
          onPressed: () => _showCreatePlaylistDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Playlist'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPlaylists(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _buildPlaylistTile(playlist, theme);
        },
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: playlist.coverUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.network(playlist.coverUrl!, fit: BoxFit.cover),
              )
            : const Icon(Icons.queue_music_rounded),
      ),
      title: Text(
        playlist.name,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${playlist.trackCount} tracks',
        style: theme.textTheme.bodySmall,
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'delete') {
            _confirmDeletePlaylist(playlist);
          }
        },
      ),
      onTap: () => _openPlaylistDetail(playlist),
    );
  }

  // ==================== ARTISTS TAB ====================

  Widget _buildArtistsTab(LibraryProvider provider, ThemeData theme) {
    final artists = provider.artists;

    if (artists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_outline,
        message: 'No artists yet',
        subtitle: 'Listen to music to see your favorite artists',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadArtists(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.85,
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _buildArtistCard(artist, theme);
        },
      ),
    );
  }

  Widget _buildArtistCard(Artist artist, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openArtistDetail(artist),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: artist.imageUrl != null
                ? NetworkImage(artist.imageUrl!)
                : null,
            child: artist.imageUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            style: theme.textTheme.labelLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (artist.verified)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: AppColors.primary),
                const SizedBox(width: 2),
                Text(
                  'Verified',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==================== ALBUMS TAB ====================

  Widget _buildAlbumsTab(LibraryProvider provider, ThemeData theme) {
    final albums = provider.albums;

    if (albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.album_outlined,
        message: 'No albums yet',
        subtitle: 'Listen to music to see albums here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAlbums(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.8,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return AuraAlbumCard(
            title: album.title,
            subtitle: album.artistName,
            imageUrl: album.coverUrl ?? 'https://picsum.photos/300?random=$index',
            onTap: () => _openAlbumDetail(album),
          );
        },
      ),
    );
  }

  // ==================== FAVORITES TAB ====================

  Widget _buildFavoritesTab(LibraryProvider provider, ThemeData theme) {
    if (provider.isLoadingFavorites && provider.favorites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final favorites = provider.favorites;

    if (favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        message: 'No favorites yet',
        subtitle: 'Tap the heart icon on songs you love',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final item = favorites[index];
          return _buildFavoriteTile(item, index, provider, theme);
        },
      ),
    );
  }

  Widget _buildFavoriteTile(MediaItem item, int index, LibraryProvider provider, ThemeData theme) {
    final playbackProvider = context.watch<PlaybackProvider>();
    final isPlaying = playbackProvider.currentMedia?.id == item.id;

    return TrackListTile(
      title: item.title,
      artist: item.artistName,
      artworkUrl: item.thumbnailUrl,
      trackNumber: index + 1,
      isPlaying: isPlaying,
      onTap: () {
        context.read<PlaybackProvider>().setQueue(provider.favorites, initialStateIndex: index);
      },
      onMoreTap: () {
        showAddToPlaylistSheet(context, item);
      },
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildLibraryItemCard(LibraryItem item, ThemeData theme, LibraryProvider provider) {
    IconData icon;
    bool isCircular = false;

    switch (item.type) {
      case LibraryItemType.playlist:
        icon = Icons.queue_music_rounded;
        break;
      case LibraryItemType.artist:
        icon = Icons.person_rounded;
        isCircular = true;
        break;
      case LibraryItemType.album:
        icon = Icons.album_rounded;
        break;
      case LibraryItemType.favorite:
        icon = Icons.favorite_rounded;
        break;
    }

    return GestureDetector(
      onTap: () {
        // Handle tap based on type
        switch (item.type) {
          case LibraryItemType.playlist:
            // Find the playlist from provider and navigate
            final playlist = provider.playlists.firstWhere(
              (p) => p.id == item.id,
              orElse: () => Playlist(id: item.id, name: item.title),
            );
            _openPlaylistDetail(playlist);
            break;
          case LibraryItemType.artist:
            final artist = provider.artists.firstWhere(
              (a) => a.id.toString() == item.id,
              orElse: () => Artist(id: int.tryParse(item.id) ?? 0, name: item.title),
            );
            _openArtistDetail(artist);
            break;
          case LibraryItemType.album:
            final album = provider.albums.firstWhere(
              (a) => a.id == item.id,
              orElse: () => Album(id: item.id, title: item.title, artistName: item.subtitle),
            );
            _openAlbumDetail(album);
            break;
          case LibraryItemType.favorite:
            // Switch to favorites tab
            _tabController.animateTo(4);
            break;
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  isCircular ? 100 : AppSpacing.radiusMd,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Center(child: Icon(icon, size: 48)),
                    )
                  : Center(child: Icon(icon, size: 48)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS & NAVIGATION ====================

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter playlist name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await context.read<LibraryProvider>().createPlaylist(
                      nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<LibraryProvider>().deletePlaylist(playlist.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetail(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _openArtistDetail(Artist artist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open artist: ${artist.name}')),
    );
  }

  void _openAlbumDetail(Album album) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open album: ${album.title}')),
    );
  }
}

// ==================== SLIVER TAB BAR DELEGATE ====================

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || isDark != oldDelegate.isDark;
  }
}
