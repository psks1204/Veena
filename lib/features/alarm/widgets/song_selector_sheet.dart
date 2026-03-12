import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/media_item.dart';
import '../../../../shared/widgets/aura_cards.dart';
import '../../../../core/services/library_service.dart';
import '../../../../core/services/api_service.dart';
import '../../search/screens/search_screen.dart'; // For search delegation if needed

class SongSelectorSheet extends StatefulWidget {
  const SongSelectorSheet({super.key});

  @override
  State<SongSelectorSheet> createState() => _SongSelectorSheetState();
}

class _SongSelectorSheetState extends State<SongSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<MediaItem> _songs = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final libraryService = context.read<LibraryService>();
    try {
      final songs = await libraryService.getFavorites();
      if (mounted) {
        setState(() {
          _songs = songs.where((s) => s.mediaType == MediaType.audio).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() => _isSearching = false);
        _loadFavorites();
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.get(
        '/media/search',
        queryParams: {'query': query, 'page': '0', 'size': '20'},
      );

      List<MediaItem> searchResults = [];
      if (results != null && results['content'] != null) {
        searchResults = (results['content'] as List)
            .map((e) => MediaItem.fromJson(e))
            .where((item) => item.mediaType == MediaType.audio)
            .toList();
      }

      if (mounted) {
        setState(() {
          _songs = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Taller for search
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Song',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.music_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? 'No songs found for "${_searchController.text}"'
                              : 'No liked songs found',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AuraTrackTile(
                          title: song.title,
                          subtitle: song.artistName,
                          imageUrl: song.thumbnailUrl,
                          playedCount: song.playedCount > 0 ? song.playedCount : null,
                          likeCount: song.likeCount > 0 ? song.likeCount : null,
                          isPlaying: false,
                          onTap: () {
                            Navigator.pop(context, song);
                          },
                          onLikeTap: null,
                          onMoreTap: null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
