import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/lyrics_model.dart';
import '../widgets/lyrics_card.dart';

/// Full Screen Player Widget - Redesigned for Spotify aesthetics
/// Responsive: Mobile stays the same, Web/Tablet gets a constrained centered layout
class FullPlayer extends StatelessWidget {
  const FullPlayer({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumName,
    this.artworkUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.duration = const Duration(minutes: 3, seconds: 30),
    this.currentPosition = Duration.zero,
    this.isShuffleOn = false,
    this.repeatMode = RepeatMode.off,
    this.lyrics,
    this.activeLyricIndex = -1,
    this.onFullscreenLyricsTap,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.onSeek,
    this.onClose,
  });

  final String trackTitle;
  final String artistName;
  final String albumName;
  final String? artworkUrl;
  final bool isPlaying;
  final double progress;
  final Duration duration;
  final Duration currentPosition;
  final bool isShuffleOn;
  final RepeatMode repeatMode;
  final Lyrics? lyrics;
  final int activeLyricIndex;
  final VoidCallback? onFullscreenLyricsTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onClose;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Debug: trace lyrics value
    debugPrint('[FullPlayer] lyrics: ${lyrics != null ? "has ${lyrics!.lines.length} lines" : "null"}');
    debugPrint('[FullPlayer] screen width: ${screenSize.width}, isLargeScreen: ${screenSize.width >= 768}');
    
    // Web/Tablet detection - only change layout for larger screens
    final isLargeScreen = screenSize.width >= 768;
    
    // For mobile: full width artwork. For web/tablet: constrained
    final artworkSize = isLargeScreen 
        ? 300.0 
        : screenSize.width - (AppSpacing.xl * 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Blurred Background layer
          if (artworkUrl != null && artworkUrl!.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Image.network(
                  artworkUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          
          // 2. Main Content layer
          SafeArea(
            child: isLargeScreen 
                ? _buildWebTabletLayout(context, theme, artworkSize)
                : _buildMobileLayout(context, theme, artworkSize),
          ),
        ],
      ),
    );
  }

  /// Web/Tablet Layout - Side by side with constrained max width
  Widget _buildWebTabletLayout(BuildContext context, ThemeData theme, double artworkSize) {
    final hasLyrics = lyrics != null && lyrics!.lines.isNotEmpty;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Artwork and controls
            Expanded(
              flex: hasLyrics ? 1 : 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        ),
                        Column(
                          children: [
                            Text(
                              'PLAYING FROM PLAYLIST',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              albumName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Artwork
                    Container(
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
                      child: artworkUrl != null && artworkUrl!.isNotEmpty
                          ? Image.network(artworkUrl!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
                            ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Track info
                    Text(
                      trackTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artistName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Progress bar
                    SizedBox(
                      width: artworkSize,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: onSeek,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(currentPosition), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: onShuffle,
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: isShuffleOn ? AppColors.primary : Colors.white60,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: onPrevious,
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onPlayPause,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 36,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onNext,
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: onRepeat,
                          icon: Icon(
                            repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                            color: repeatMode != RepeatMode.off ? AppColors.primary : Colors.white60,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bottom icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.devices_rounded, color: Colors.white60, size: 20),
                        SizedBox(width: 24),
                        Icon(Icons.share_outlined, color: Colors.white60, size: 18),
                        SizedBox(width: 24),
                        Icon(Icons.list_rounded, color: Colors.white60, size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Right side - Lyrics (always show if available)
            if (lyrics != null && lyrics!.lines.isNotEmpty)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lyrics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: onFullscreenLyricsTap,
                            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _WebLyricsView(
                          lyrics: lyrics!,
                          activeIndex: activeLyricIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mobile Layout - Original design (unchanged)
  Widget _buildMobileLayout(BuildContext context, ThemeData theme, double artworkSize) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Top navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                ),
                Column(
                  children: [
                    Text(
                      'PLAYING FROM PLAYLIST',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      albumName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Artwork section
          Center(
            child: Hero(
              tag: 'player_artwork',
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
                child: artworkUrl != null && artworkUrl!.isNotEmpty
                    ? Image.network(artworkUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Meta info and Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackTitle,
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
                        artistName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: onSeek,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(currentPosition), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(_formatDuration(duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onShuffle,
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: isShuffleOn ? AppColors.primary : Colors.white60,
                    size: 26,
                  ),
                ),
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 44),
                ),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 44),
                ),
                IconButton(
                  onPressed: onRepeat,
                  icon: Icon(
                    repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: repeatMode != RepeatMode.off ? AppColors.primary : Colors.white60,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bottom mini controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.devices_rounded, color: Colors.white60, size: 24),
                Spacer(),
                Icon(Icons.share_outlined, color: Colors.white60, size: 22),
                SizedBox(width: 24),
                Icon(Icons.list_rounded, color: Colors.white60, size: 26),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Lyrics Section
          if (lyrics != null && lyrics!.lines.isNotEmpty) ...[
            LyricsCard(
              lyrics: lyrics!,
              activeIndex: activeLyricIndex,
              onFullscreenTap: onFullscreenLyricsTap,
            ),
            const SizedBox(height: 60),
          ],

          // "About the artist" section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      if (artworkUrl != null)
                        Image.network(
                          artworkUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: Text(
                          'About the artist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Listening to $artistName is a soul-refreshing experience. More bio details would be fetched from API.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Follow'),
                        ),
                      ],
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
}

/// Web Lyrics View - Shows lyrics with auto-scroll for web/tablet
class _WebLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final int activeIndex;

  const _WebLyricsView({
    required this.lyrics,
    required this.activeIndex,
  });

  @override
  State<_WebLyricsView> createState() => _WebLyricsViewState();
}

class _WebLyricsViewState extends State<_WebLyricsView> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 50.0;

  @override
  void didUpdateWidget(_WebLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex && widget.activeIndex >= 0) {
      _scrollToActiveLine();
    }
  }

  void _scrollToActiveLine() {
    if (!_scrollController.hasClients) return;
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.lines.length) return;
    
    final targetOffset = widget.activeIndex * _itemHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 100),
      itemCount: widget.lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics.lines[index];
        final isActive = index == widget.activeIndex;
        
        return Container(
          height: _itemHeight,
          alignment: Alignment.centerLeft,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: isActive ? 20 : 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
            child: Text(
              line.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

enum RepeatMode { off, all, one }
