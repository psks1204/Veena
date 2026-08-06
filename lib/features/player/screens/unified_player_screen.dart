import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/player_provider.dart' hide RepeatMode;
import '../../../core/providers/player_provider.dart' as pp show RepeatMode;
import '../../../core/models/media_item.dart';
import '../../../core/models/media_download_models.dart';
import '../../../core/services/artist_service.dart';
import '../../../core/services/library_service.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../library/widgets/add_to_playlist_sheet.dart';
import '../../../shared/widgets/lyrics_card.dart';
import '../../../shared/widgets/share_song_button.dart';
import 'lyrics_fullscreen_screen.dart';
import '../../../core/models/artist.dart';
import '../../library/screens/artist_detail_screen.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/media_service.dart';
import '../widgets/comments_sheet.dart';
import '../../../shared/widgets/player_artwork_ad_swap.dart';
import '../../../shared/widgets/player_ad_rotator.dart';
import '../../../shared/widgets/subscription_modal.dart';
import '../../../shared/utils/count_formatter.dart';
import '../services/karaoke_recording_service.dart';
import '../widgets/karaoke_reel_post_sheet.dart';

/// Unified Player Screen - Spotify-style player that handles both Audio and Video
///
/// This is a single screen that adapts its display based on media type:
/// - Audio: Shows artwork, lyrics, and standard audio controls
/// - Video: Shows video player in place of artwork with same controls
///
/// Switching between audio and video happens seamlessly within the same screen.
class UnifiedPlayerScreen extends StatefulWidget {
  const UnifiedPlayerScreen({super.key});

  @override
  State<UnifiedPlayerScreen> createState() => _UnifiedPlayerScreenState();
}

class _UnifiedPlayerScreenState extends State<UnifiedPlayerScreen> {
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Allow all orientations for video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _focusNode.dispose();

    // Reset to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _hideControlsAfterDelay() {
    _hideControlsTimer?.cancel();

    // Only auto-hide controls for video in fullscreen/landscape
    final player = context.read<PlayerProvider>();
    if (!player.isVideo || !_isFullscreen) return;

    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && context.read<PlayerProvider>().isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _toggleFullscreen() {
    final player = context.read<PlayerProvider>();
    if (!player.isVideo) return;

    if (_isFullscreen) {
      // Exit fullscreen
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() {
        _isFullscreen = false;
        _showControls = true;
      });
    } else {
      // Enter fullscreen (landscape)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() {
        _isFullscreen = true;
        _showControls = true;
      });
      _hideControlsAfterDelay();
    }
  }

  void _handleClose() {
    if (_isFullscreen) {
      // Exit fullscreen first
      _toggleFullscreen();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleKeyEvent(KeyEvent event, PlayerProvider player) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      player.togglePlayPause();
    } else if (event.logicalKey == LogicalKeyboardKey.keyF && player.isVideo) {
      _toggleFullscreen();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleClose();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final newPos = player.position - const Duration(seconds: 10);
      player.seek(newPos < Duration.zero ? Duration.zero : newPos);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final newPos = player.position + const Duration(seconds: 10);
      player.seek(newPos > player.duration ? player.duration : newPos);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQueueSheet(PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Queue content
            Expanded(
              child: player.queue.isEmpty
                  ? Center(
                      child: Text(
                        'Queue is empty',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: player.queue.length,
                      itemBuilder: (context, index) {
                        final item = player.queue[index];
                        final isPlaying = player.currentMedia?.id == item.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.thumbnailUrl != null
                                ? Image.network(
                                    item.thumbnailUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                    ),
                                  ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isPlaying
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: isPlaying
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.artistName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 1,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPlaying)
                                const Icon(
                                  Icons.equalizer_rounded,
                                  color: AppColors.primary,
                                ),
                              IconButton(
                                tooltip: 'Remove from queue',
                                onPressed: () async {
                                  await player.removeFromQueueAt(index);
                                  if (!context.mounted) return;
                                  if (!player.hasMedia) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            player.playQueueIndex(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasMedia) {
          // No media - close the player
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fullscreen video mode
        if (_isFullscreen && player.isVideo) {
          return _buildFullscreenVideoPlayer(player);
        }

        // Normal mode (portrait) - works for both audio and video
        return _buildNormalPlayer(player);
      },
    );
  }

  /// Fullscreen video player (landscape mode)
  Widget _buildFullscreenVideoPlayer(PlayerProvider player) {
    final controller = player.videoController;
    final isValid =
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, player),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              if (isValid)
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),

              // Controls overlay
              if (_showControls)
                _buildVideoControlsOverlay(player, isFullscreen: true),
            ],
          ),
        ),
      ),
    );
  }

  /// Normal player layout (portrait mode) - handles both audio and video
  Widget _buildNormalPlayer(PlayerProvider player) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width >= 768;
    final artworkSize = isLargeScreen
        ? 240.0
        : screenSize.width - (AppSpacing.xl * 2);

    final media = player.currentMedia!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background (use thumbnail for both audio and video)
          if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Image.network(
                  media.thumbnailUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: isLargeScreen
                ? _buildWebLayout(player, theme, artworkSize)
                : _buildMobileLayout(player, theme, artworkSize),
          ),
        ],
      ),
    );
  }

  /// Mobile layout
  Widget _buildMobileLayout(
    PlayerProvider player,
    ThemeData theme,
    double artworkSize,
  ) {
    final media = player.currentMedia!;
    final isVideo = player.isVideo;

    // For video, use a non-scrollable layout with video centered and controls at bottom
    if (isVideo) {
      return _buildVideoMobileLayout(player, theme, media, artworkSize);
    }

    // For audio, use the scrollable layout with lyrics
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Top bar
          _buildMobileTopBar(player, theme, media, isVideo),

          const SizedBox(height: 40),

          // Artwork
          Center(
            child: Container(
              width: artworkSize,
              height: artworkSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildArtworkContent(media),
            ),
          ),

          const SizedBox(height: 60),

          // Track info and Add button
          _buildTrackInfo(player, media),

          const SizedBox(height: 20),

          // Progress bar
          _buildProgressBar(player),

          const SizedBox(height: 10),

          // Main controls
          _buildMainControls(player),

          const SizedBox(height: 20),

          // Switch media button and queue
          _buildBottomActions(player),

          const SizedBox(height: 16),

          // Karaoke recording section (only for karaoke songs)
          if (media.isKaraoke) _buildKaraokeRecordingSection(player, media),

          // Rotates between existing promo banner and ad banner on mobile.
          const PlayerAdRotator(),

          // Lyrics section for audio
          if (player.currentLyrics != null) _buildLyricsSection(player),

          const SizedBox(height: 24),

          // About the artist card (Spotify style)
          _buildArtistCard(media),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Video-specific mobile layout - Spotify style
  /// Edge-to-edge video at top, switch button, track info with small artwork, artist card
  Widget _buildVideoMobileLayout(
    PlayerProvider player,
    ThemeData theme,
    MediaItem media,
    double artworkSize,
  ) {
    final linkedMedia = media.linkedMedia;
    final hasLinkedMedia = linkedMedia != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar (minimal - just close and menu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _handleClose,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Text(
                  'PLAYING RECOMMENDED TRACKS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 32), // Balance for back button
                ShareSongButton(media: media),
              ],
            ),
          ),

          // Edge-to-edge video player
          GestureDetector(
            onTap: () => player.togglePlayPause(),
            onDoubleTap: _toggleFullscreen,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _buildVideoContent(
                  player,
                  MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),

          // Switch to audio button
          if (hasLinkedMedia)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GestureDetector(
                onTap: () => _switchToLinkedMedia(player, media, linkedMedia),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Switch to audio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Track info row with small thumbnail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Small album artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[900],
                    child: media.thumbnailUrl != null
                        ? Image.network(media.thumbnailUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        media.fullArtistString,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildEngagementStats(media),
                      _buildCreditsSection(media),
                    ],
                  ),
                ),
                // Add button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerDownloadButton(media),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              AddToPlaylistSheet(mediaItem: media),
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress bar
          _buildProgressBar(player),

          const SizedBox(height: 16),

          // Main controls
          _buildMainControls(player),

          const SizedBox(height: 16),

          // Secondary actions row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fullscreen button
                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                Row(
                  children: [
                    if (context.watch<AppSettingsService>().enableComments)
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                CommentsSheet(mediaId: media.id),
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    IconButton(
                      onPressed: () => _showQueueSheet(player),
                      icon: const Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About the artist card
          _buildArtistCard(media),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Switch to linked audio/video
  void _switchToLinkedMedia(
    PlayerProvider player,
    MediaItem current,
    LinkedMediaInfo linkedMedia,
  ) {
    final currentPosition = player.position;
    final newItem = MediaItem.fromLinkedMedia(
      linkedMedia,
      currentMedia: current,
    );
    player.play(newItem, startPosition: currentPosition);
  }

  /// About the artist card - Spotify style
  Widget _buildArtistCard(MediaItem media) {
    final artistName = media.artistName;
    final artistImage = media.artist?.imageUrl ?? media.thumbnailUrl;

    return GestureDetector(
      onTap: () {
        Artist? theArtist;
        if (media.artist != null) {
          theArtist = Artist(
            id: media.artist!.id.toString(),
            name: media.artist!.name,
            imageUrl: media.artist!.imageUrl,
            verified: media.artist!.verified,
            followerCount: media.artist!.followerCount,
            totalPlays: media.playedCount,
          );
        } else if (media.artistId != null) {
          theArtist = Artist(
            id: media.artistId!,
            name: artistName,
            imageUrl: artistImage,
            followerCount: media.artist?.followerCount ?? 0,
            totalPlays: media.playedCount,
          );
        }

        if (theArtist != null) {
          final validArtist = theArtist;
          _handleClose();
          AppNavigation.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(artist: validArtist),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist image with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: artistImage != null
                        ? Image.network(
                            artistImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white38,
                                  size: 48,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white38,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                ),
                // "About the artist" label with gradient
                Positioned(
                  top: 16,
                  left: 16,
                  child: Text(
                    'About the artist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // Artist info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                artistName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Verified badge (if artist is verified)
                            if (media.artist?.verified == true)
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          media.artist?.genre ?? 'Artist',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Follow button
                  Consumer<ArtistService>(
                    builder: (context, artistService, _) {
                      if (media.artistId == null) {
                        return const SizedBox.shrink();
                      }
                      final library = context.watch<LibraryService>();
                      final isFollowing = library.artists.any(
                        (a) => a.id == media.artistId,
                      );

                      return GestureDetector(
                        onTap: () async {
                          await artistService.toggleFollow(media.artistId!);
                          await context.read<LibraryService>().getArtists();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? Colors.transparent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFollowing
                                  ? Colors.white
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: isFollowing ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Credits section - Spotify style
  Widget _buildCreditsSection(MediaItem media, {bool centered = false}) {
    final List<Widget> creditWidgets = [];

    void addCredit(String label, String? name) {
      if (name != null && name.isNotEmpty) {
        creditWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$label: $name',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: centered ? TextAlign.center : TextAlign.start,
            ),
          ),
        );
      }
    }

    addCredit('Lyricist', media.lyricist?.name ?? media.lyricistName);
    addCredit('Composer', media.composer?.name ?? media.composerName);
    addCredit('Producer', media.producer?.name ?? media.producerName);
    addCredit('Director', media.director?.name ?? media.directorName);

    if (creditWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: creditWidgets,
    );
  }

  Widget _buildEngagementStats(MediaItem media, {bool centered = false}) {
    return Consumer<MediaService>(
      builder: (context, mediaService, _) {
        final linkedId = media.linkedMediaId ?? media.linkedMedia?.id;
        final likeCount = mediaService.getLikeCount(
          media.id,
          linkedMediaId: linkedId,
          initial: media.likeCount,
        );
        final labelColor = Colors.white.withOpacity(0.78);

        return Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centered
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(Icons.play_arrow_rounded, color: labelColor, size: 14),
            const SizedBox(width: 2),
            Text(
              formatCompactCount(media.playedCount),
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '·',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.favorite_rounded, color: labelColor, size: 12),
            const SizedBox(width: 4),
            Text(
              formatCompactCount(likeCount),
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mobile top bar widget
  Widget _buildMobileTopBar(
    PlayerProvider player,
    ThemeData theme,
    MediaItem media,
    bool isVideo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isVideo ? 'NOW PLAYING VIDEO' : 'NOW PLAYING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                Text(
                  media.fullArtistString,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Share button
          ShareSongButton(media: media),
        ],
      ),
    );
  }

  /// Track info widget
  Widget _buildTrackInfo(PlayerProvider player, MediaItem media) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  media.fullArtistString,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildEngagementStats(media),
                _buildCreditsSection(media),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddToPlaylistSheet(mediaItem: media),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          _buildPlayerDownloadButton(media),
        ],
      ),
    );
  }

  Future<void> _handleDownloadTap(MediaItem media) async {
    if (media.isChannelMedia) return;

    final subscription = context.read<SubscriptionProvider>();
    if (!subscription.isNoAdsSubscribed) {
      await subscription.refreshStatus();
      if (!mounted) return;
    }

    if (!subscription.isNoAdsSubscribed) {
      await showSubscriptionModal(context);
      return;
    }

    final result = await context.read<DownloadProvider>().downloadMedia(media);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result.status) {
      case MediaDownloadStatus.success:
        messenger.showSnackBar(
          const SnackBar(content: Text('Downloaded for offline playback')),
        );
        break;
      case MediaDownloadStatus.alreadyDownloaded:
        messenger.showSnackBar(
          const SnackBar(content: Text('Media already downloaded')),
        );
        break;
      case MediaDownloadStatus.inProgress:
        messenger.showSnackBar(
          const SnackBar(content: Text('Download already in progress')),
        );
        break;
      case MediaDownloadStatus.notSubscribed:
        await showSubscriptionModal(context);
        break;
      case MediaDownloadStatus.unsupportedPlatform:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Downloads are available on Android and iOS only'),
          ),
        );
        break;
      case MediaDownloadStatus.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to download media')),
        );
        break;
    }
  }

  Widget _buildPlayerDownloadButton(MediaItem media) {
    final downloadProvider = context.watch<DownloadProvider>();
    final subscription = context.watch<SubscriptionProvider>();

    if (!downloadProvider.isPlatformSupported || media.isChannelMedia) {
      return const SizedBox.shrink();
    }

    final isDownloaded = downloadProvider.isDownloaded(media.id);
    final isDownloading = downloadProvider.isDownloading(media.id);
    final isSubscribed = subscription.isNoAdsSubscribed;

    if (isDownloading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      onPressed: isDownloaded ? null : () => _handleDownloadTap(media),
      tooltip: isDownloaded
          ? 'Downloaded'
          : isSubscribed
          ? 'Download'
          : 'Download (Premium)',
      icon: Icon(
        isDownloaded
            ? Icons.download_done_rounded
            : isSubscribed
            ? Icons.download_rounded
            : Icons.lock_rounded,
        color: isDownloaded
            ? Colors.greenAccent
            : isSubscribed
            ? Colors.white70
            : Colors.white54,
        size: 24,
      ),
    );
  }

  /// Video content widget
  Widget _buildVideoContent(PlayerProvider player, double width) {
    final controller = player.videoController;
    final isValid =
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;

    if (!isValid) {
      final hasError =
          controller?.value.hasError ??
          (!player.isLoading && controller == null);

      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasError) ...[
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Playback Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller?.value.errorDescription ??
                      'Failed to initialize video',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => player.play(player.currentMedia!),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => player.togglePlayPause(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          // Play/pause overlay
          if (!player.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
        ],
      ),
    );
  }

  /// Artwork content widget
  Widget _buildArtworkContent(MediaItem media) {
    return PlayerArtworkAdSwap(thumbnailUrl: media.thumbnailUrl);
  }

  /// Progress bar
  Widget _buildProgressBar(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 4,
            ),
            child: Slider(
              value: player.progress.clamp(0.0, 1.0),
              onChanged: (value) => player.seekToProgress(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(player.position),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  _formatDuration(player.duration),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main playback controls
  Widget _buildMainControls(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: player.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: player.shuffleEnabled ? AppColors.primary : Colors.white54,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: player.previous,
            icon: const Icon(
              Icons.skip_previous_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          GestureDetector(
            onTap: player.togglePlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                player.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),
          ),
          IconButton(
            onPressed: player.next,
            icon: const Icon(
              Icons.skip_next_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          IconButton(
            onPressed: player.toggleRepeatMode,
            icon: Icon(
              player.repeatMode == pp.RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: player.repeatMode != pp.RepeatMode.off
                  ? AppColors.primary
                  : Colors.white54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action buttons (switch media, queue)
  Widget _buildBottomActions(PlayerProvider player) {
    final linkedMedia = player.currentMedia?.linkedMedia;
    final hasLinkedMedia = linkedMedia != null;

    final settings = context.watch<AppSettingsService>();
    final showComments = settings.enableComments;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Switch to linked media button
          if (hasLinkedMedia)
            GestureDetector(
              onTap: () => _switchToLinkedMedia(
                player,
                player.currentMedia!,
                linkedMedia,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        linkedMedia.mediaType == MediaType.video
                            ? Icons.videocam_rounded
                            : Icons.music_note_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      linkedMedia.mediaType == MediaType.video
                          ? 'Watch Video'
                          : 'Listen to Audio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          Row(
            children: [
              if (showComments)
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          CommentsSheet(mediaId: player.currentMedia!.id),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              IconButton(
                onPressed: () => _showQueueSheet(player),
                icon: const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Karaoke recording section — only shown for karaoke tracks.
  ///
  /// Displays a record button when idle, a live timer when recording,
  /// and auto-stops when the song completes.
  Widget _buildKaraokeRecordingSection(
    PlayerProvider player,
    MediaItem media,
  ) {
    return Consumer<KaraokeRecordingService>(
      builder: (context, recordingService, _) {
        // Auto-stop recording when song ends
        if (recordingService.isRecording &&
            player.duration.inSeconds > 0 &&
            player.position >= player.duration) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await player.pause();
            await recordingService.stopRecording();
            if (!mounted) return;
            _showReelPostSheet(media);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 12,
          ),
          child: Column(
            children: [
              // Recording indicator + button
              if (recordingService.isIdle || recordingService.hasError)
                _buildKaraokeIdleState(recordingService)
              else if (recordingService.isRecording)
                _buildKaraokeRecordingState(recordingService, media, player),

              // Error message
              if (recordingService.hasError &&
                  recordingService.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    recordingService.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Idle state: pulsing mic button + "Record your cover" label.
  Widget _buildKaraokeIdleState(KaraokeRecordingService recordingService) {
    return GestureDetector(
      onTap: () async {
        if (!recordingService.isPlatformSupported) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording is only available on mobile'),
            ),
          );
          return;
        }
        await recordingService.startRecording();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF416C).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated mic icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Record Your Cover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Recording state: live timer + animated indicator + stop button.
  Widget _buildKaraokeRecordingState(
    KaraokeRecordingService recordingService,
    MediaItem media,
    PlayerProvider player,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF416C).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // Pulsing red dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(value * 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
            onEnd: () {
              // Trigger rebuild to keep pulsing
              if (mounted && recordingService.isRecording) {
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 12),

          // "Recording" label
          const Text(
            'REC',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),

          // Timer
          Expanded(
            child: Text(
              KaraokeRecordingService.formatDuration(
                recordingService.recordingDuration,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          // Stop button
          GestureDetector(
            onTap: () async {
              await player.pause();
              await recordingService.stopRecording();
              if (!mounted) return;
              _showReelPostSheet(media);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Stop',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show the reel posting bottom sheet after recording stops.
  void _showReelPostSheet(MediaItem media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => KaraokeReelPostSheet(sourceMedia: media),
    ).then((posted) {
      if (posted == true) {
        // Recording was posted — reset state
        context.read<KaraokeRecordingService>().reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Your karaoke cover has been posted!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (posted == false) {
        // User discarded — service already reset in the sheet
      }
      // null = dismissed without action, keep stopped state
    });
  }

  /// Lyrics section
  Widget _buildLyricsSection(PlayerProvider player) {
    final lyrics = player.currentLyrics;
    if (lyrics == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: LyricsCard(
        lyrics: lyrics,
        activeIndex: player.activeLyricIndex,
        onFullscreenTap: () {
          // Capture current values before navigation to avoid null reference
          final currentLyrics = player.currentLyrics;
          if (currentLyrics == null) return;

          final activeIndex = player.activeLyricIndex;
          final stream = player.lyricIndexStream;

          // Use rootNavigator to push on top of the player screen
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => LyricsFullscreenScreen(
                lyrics: currentLyrics,
                initialActiveIndex: activeIndex,
                activeIndexStream: stream,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Video controls overlay (for fullscreen mode)
  Widget _buildVideoControlsOverlay(
    PlayerProvider player, {
    bool isFullscreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _handleClose,
                  icon: Icon(
                    isFullscreen
                        ? Icons.arrow_back_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        player.currentMedia?.title ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        player.currentMedia?.fullArtistString ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer to balance the back button
                ShareSongButton(media: player.currentMedia!),
              ],
            ),
          ),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white30,
                    thumbColor: AppColors.primary,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: player.progress.clamp(0.0, 1.0),
                    onChanged: (v) => player.seekToProgress(v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(player.position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(player.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: player.previous,
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: player.togglePlayPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          player.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: player.next,
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      onPressed: _toggleFullscreen,
                      icon: Icon(
                        isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Web/Tablet layout
  /// Web layout - Spotify-style centered design
  Widget _buildWebLayout(
    PlayerProvider player,
    ThemeData theme,
    double artworkSize,
  ) {
    final media = player.currentMedia!;
    final isVideo = player.isVideo;
    final linkedMedia = media.linkedMedia;
    final hasLinkedMedia = linkedMedia != null;

    // Calculate sizes for web
    final maxContentWidth = 500.0;
    final mediaWidth = isVideo ? maxContentWidth : 280.0;
    final mediaHeight = isVideo ? mediaWidth * 9 / 16 : 280.0;

    return Stack(
      children: [
        // Main content - centered scrollable column
        Positioned.fill(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top bar with close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _handleClose,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Close',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            tooltip: 'More options',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Artwork/Video - large and centered
                    Container(
                      width: mediaWidth,
                      height: mediaHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isVideo ? 12 : 8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 60,
                            offset: const Offset(0, 30),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isVideo
                          ? _buildVideoContent(player, mediaWidth)
                          : _buildArtworkContent(media),
                    ),

                    // Fullscreen button for video
                    if (isVideo)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: _toggleFullscreen,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fullscreen',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Track Title - centered with ellipsis for long names
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        media.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Artist name
                    // Artist name & Credits
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            media.fullArtistString,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          _buildEngagementStats(media, centered: true),
                          _buildCreditsSection(media, centered: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Web Follow Button
                    Consumer<ArtistService>(
                      builder: (context, artistService, _) {
                        if (media.artistId == null) {
                          return const SizedBox.shrink();
                        }
                        final library = context.watch<LibraryService>();
                        final isFollowing = library.artists.any(
                          (a) => a.id == media.artistId,
                        );

                        return GestureDetector(
                          onTap: () async {
                            await artistService.toggleFollow(media.artistId!);
                            await context.read<LibraryService>().getArtists();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isFollowing
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing
                                    ? AppColors.primary
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Controls container (rounded card with progress + controls)
                    Container(
                      width: maxContentWidth - 32,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Progress bar with times
                          _buildWebProgressBar(player),

                          const SizedBox(height: 24),

                          // Main controls
                          _buildWebMainControls(player),

                          // Karaoke recording for web layout
                          if (media.isKaraoke) ...[
                            const SizedBox(height: 16),
                            _buildKaraokeRecordingSection(player, media),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom left - Switch media button
        if (hasLinkedMedia)
          Positioned(
            left: 24,
            bottom: 24,
            child: GestureDetector(
              onTap: () => _switchToLinkedMedia(player, media, linkedMedia),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isVideo
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isVideo ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVideo
                            ? Icons.music_note_rounded
                            : Icons.play_arrow_rounded,
                        color: isVideo ? AppColors.primary : Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isVideo ? 'Listen to Audio' : 'Watch Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom right - Queue & Comments buttons
        Positioned(
          right: 24,
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (context.watch<AppSettingsService>().enableComments)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentsSheet(mediaId: media.id),
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Comments',
                  ),
                ),
              IconButton(
                onPressed: () => _showQueueSheet(player),
                icon: const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
                tooltip: 'Queue',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Web progress bar with styled slider
  Widget _buildWebProgressBar(PlayerProvider player) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 4,
          ),
          child: Slider(
            value: player.progress.clamp(0.0, 1.0),
            onChanged: (v) => player.seekToProgress(v),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(player.position),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(player.duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Web main controls - centered with proper sizing
  Widget _buildWebMainControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          onPressed: () => player.toggleShuffle(),
          icon: Icon(
            Icons.shuffle_rounded,
            color: player.shuffleEnabled ? AppColors.primary : Colors.white70,
            size: 22,
          ),
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 16),

        // Previous
        IconButton(
          onPressed: () => player.previous(),
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: Colors.white,
            size: 36,
          ),
          tooltip: 'Previous',
        ),
        const SizedBox(width: 8),

        // Play/Pause - large circular button
        GestureDetector(
          onTap: () => player.togglePlayPause(),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Next
        IconButton(
          onPressed: () => player.next(),
          icon: const Icon(
            Icons.skip_next_rounded,
            color: Colors.white,
            size: 36,
          ),
          tooltip: 'Next',
        ),
        const SizedBox(width: 16),

        // Repeat
        IconButton(
          onPressed: () => player.toggleRepeatMode(),
          icon: Icon(
            player.repeatMode == pp.RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: player.repeatMode != pp.RepeatMode.off
                ? AppColors.primary
                : Colors.white70,
            size: 22,
          ),
          tooltip: 'Repeat',
        ),
      ],
    );
  }
}
