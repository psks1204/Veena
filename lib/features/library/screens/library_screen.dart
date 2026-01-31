import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/services/library_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/video_player_screen.dart';
import '../../auth/services/auth_service.dart';
import 'playlist_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'album_detail_screen.dart';
import 'albums_browse_screen.dart';

/// Library Screen - Spotify-like Premium Design
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'Playlists'; // Default to Playlists
  final List<String> _filters = ['Playlists', 'Artists', 'Albums', 'Favorites'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibrary();
    });
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    try {
      await context.read<LibraryService>().fetchLibrary();
    } catch (e) {
      debugPrint('Error loading library: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
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
                await context.read<LibraryService>().createPlaylist(nameController.text);
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
                      final authService = context.watch<AuthService>();
                      final userPicture = authService.userPicture;
                      final userInitials = authService.userInitials;
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        backgroundImage: userPicture != null ? NetworkImage(userPicture) : null,
                        child: userPicture == null ? Text(userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)) : null,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = isSelected ? 'All' : filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  Icon(Icons.swap_vert_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
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
                  Icon(Icons.grid_view_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
        bool showLikedSongsTile = (_selectedFilter == 'All' || _selectedFilter == 'Playlists');
        
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
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
                    MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: item)),
                  );
                  _loadLibrary(); // Refresh on return
                },
              );
            } else if (item is Artist) {
              return _buildLibraryTile(
                title: item.name,
                subtitle: 'Artist',
                imageUrl: item.imageUrl,
                isCircle: true,
                onTap: () {
                   AppNavigation.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: item)),
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
                    MaterialPageRoute(builder: (_) => AlbumDetailScreen(
                      albumId: item.id,
                      title: item.title,
                      artist: item.artistName,
                      coverUrl: item.coverUrl,
                    )),
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
                color: isLikedSongs ? const Color(0xFF5038A0) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: isLikedSongs 
                  ? const Center(child: Icon(Icons.favorite_rounded, color: Colors.white, size: 28))
                  : (imageUrl == null || imageUrl.isEmpty
                      ? Icon(isCircle ? Icons.person_rounded : Icons.music_note_rounded, color: Colors.grey)
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
                      color: isPlaying ? AppColors.primary : (isLikedSongs ? AppColors.primary : (isDark ? Colors.white : Colors.black)),
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
                          child: Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 14),
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
          ],
        ),
      ),
    );
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
                  onPressed: favorites.isEmpty ? null : () {
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
                  onPressed: favorites.isEmpty ? null : () {
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                final isItemPlaying = playerWatch.currentMedia?.id == item.id;
                return _buildLibraryTile(
                  title: item.title,
                  subtitle: 'Song • ${item.description ?? item.artistName ?? ''}',
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
