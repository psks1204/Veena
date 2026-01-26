import 'package:flutter/material.dart';
import '../../../core/models/lyrics_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Premium Lyrics Card - Spotify Style
class LyricsCard extends StatefulWidget {
  final Lyrics lyrics;
  final int activeIndex;
  final VoidCallback? onFullscreenTap;

  const LyricsCard({
    super.key,
    required this.lyrics,
    required this.activeIndex,
    this.onFullscreenTap,
  });

  @override
  State<LyricsCard> createState() => _LyricsCardState();
}

class _LyricsCardState extends State<LyricsCard> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 90.0; // Increased for longer lyrics
  static const double _viewportHeight = 350.0; // Increased to fit taller items
  
  // Padding to allow first/last items to be centered
  double get _centerPadding => (_viewportHeight / 2) - (_itemHeight / 2);


  @override
  void didUpdateWidget(LyricsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.activeIndex != widget.activeIndex && widget.activeIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine();
      });
    }
  }

  void _scrollToActiveLine() {
    if (!_scrollController.hasClients) return;
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.lines.length) return;
    
    // Target offset = index * itemHeight
    // The padding ensures that when we scroll to this offset,
    // the item appears centered in the viewport
    final targetOffset = widget.activeIndex * _itemHeight;
    
    // Clamp to valid scroll range
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1c).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                onTap: widget.onFullscreenTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'FULLSCREEN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: _viewportHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ListView.builder(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: _centerPadding),
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
                        fontSize: isActive ? 22 : 18,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                      child: Text(
                        line.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
