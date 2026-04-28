import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/artist.dart';
import '../../../core/services/media_service.dart';
import '../../../core/providers/player_provider.dart';
import '../../../shared/widgets/aura_cards.dart';
import '../../player/screens/unified_player_screen.dart';
import '../../../shared/widgets/media_options_sheet.dart';
import '../../../core/services/library_service.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../library/screens/artist_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Search Screen
///
/// Premium search experience with:
/// - Real-time API search with debouncing
/// - Browse categories
/// - Search results with tracks, artists, albums
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _debounceTimer;

  List<MediaItem> _searchResults = [];
  List<Artist> _searchArtists = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isListening = false;
  bool _speechReady = false;

  /// Voice search is only supported on Android and iOS.
  bool get _isVoiceSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _searchResults = [];
        _searchArtists = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final mediaService = context.read<MediaService>();
      final results = await mediaService.search(query);

      setState(() {
        _searchResults = results;
        _searchArtists = mediaService.searchArtists;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
      debugPrint('Search error: $e');
    }
  }

  void _playMedia(MediaItem item) {
    final player = context.read<PlayerProvider>();

    player.play(item);

    if (item.isVideo) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()));
    }
  }

  void _toggleLike(MediaItem item) async {
    final mediaService = context.read<MediaService>();
    final libraryService = context.read<LibraryService>();

    await mediaService.toggleLike(item.id, initial: item.liked);

    // Update local state for immediate UI reflection
    if (mediaService.isLiked(item.id, initial: item.liked)) {
      libraryService.addFavoriteLocal(item);
    } else {
      libraryService.removeFavoriteLocal(item.id);
    }

    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MediaService>().clearSearch();
    setState(() {
      _isSearching = false;
      _hasSearched = false;
      _searchResults = [];
      _searchArtists = [];
    });
  }

  Future<void> _toggleVoiceSearch() async {
    if (!_isVoiceSupported) return;
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    // Request microphone permission before initialising speech on Android
    if (Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Microphone permission is required for voice search',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }
    }

    // Re-initialise each time so a previously-denied permission is picked up
    _speechReady = false;
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice search is unavailable on this device'),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      // ignore: deprecated_member_use
      listenMode: stt.ListenMode.search,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;

        _searchController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _onSearchChanged(text);

        if (result.finalResult) {
          _speech.stop();
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with search
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            title: Text(
              'Search',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you want to listen to?',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: _clearSearch,
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          if (_isVoiceSupported)
                            IconButton(
                              onPressed: _toggleVoiceSearch,
                              icon: Icon(
                                _isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                color: _isListening
                                    ? AppColors.primary
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                              ),
                            ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_hasSearched)
            _buildSearchResults(theme)
          else
            _buildBrowseCategories(theme, colorScheme),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    final mediaService = context.watch<MediaService>();
    final player = context.watch<PlayerProvider>();
    final isDark = theme.brightness == Brightness.dark;

    final totalResults = _searchResults.length + _searchArtists.length;

    if (totalResults == 0) {
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
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No results found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Separate by type
    final videos = _searchResults.where((m) => m.isVideo).toList();
    final audios = _searchResults.where((m) => m.isAudio).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Results count
          Text(
            '$totalResults results',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Artists section
          if (_searchArtists.isNotEmpty) ...[
            Text(
              'Artists',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _searchArtists.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final artist = _searchArtists[index];
                  return _buildArtistSearchCard(context, artist, isDark, theme);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Videos section
          if (videos.isNotEmpty) ...[
            Text(
              'Videos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = videos[index];
                  return SizedBox(
                    width: 160,
                    child: AuraAlbumCard(
                      title: item.title,
                      subtitle: item.artistName,
                      imageUrl: item.thumbnailUrl ?? '',
                      mediaType: item.mediaType,
                      isLiked: mediaService.isLiked(
                        item.id,
                        initial: item.liked,
                      ),
                      onTap: () => _playMedia(item),
                      onLikeTap: () => _toggleLike(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Audio tracks section
          if (audios.isNotEmpty) ...[
            Text(
              'Tracks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...audios.map((item) {
              final isPlaying = player.currentMedia?.id == item.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AuraTrackTile(
                  title: item.title,
                  subtitle: item.artistName,
                  imageUrl: item.thumbnailUrl,
                  isPlaying: isPlaying,
                  isLiked: mediaService.isLiked(item.id, initial: item.liked),
                  playedCount: item.playedCount > 0 ? item.playedCount : null,
                  likeCount: item.likeCount > 0 ? item.likeCount : null,
                  onTap: () => _playMedia(item),
                  onLikeTap: () => _toggleLike(item),
                  onMoreTap: () {
                    MediaOptionsSheet.show(context, mediaItem: item);
                  },
                ),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _buildArtistSearchCard(
    BuildContext context,
    Artist artist,
    bool isDark,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        AppNavigation.push(
          context,
          MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: artist)),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            // Circular artist image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Center(
                            child: Text(
                              artist.name.isNotEmpty
                                  ? artist.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Center(
                            child: Text(
                              artist.name.isNotEmpty
                                  ? artist.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Center(
                          child: Text(
                            artist.name.isNotEmpty
                                ? artist.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              artist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (artist.verified)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.verified,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                Text(
                  'Artist',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCategories(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 56,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Search for music',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find your favourite songs, artists\nand albums',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
