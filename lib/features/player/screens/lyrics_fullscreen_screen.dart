import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/lyrics_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class LyricsFullscreenScreen extends StatefulWidget {
  final Lyrics lyrics;
  final int initialActiveIndex;
  final Stream<int> activeIndexStream;

  const LyricsFullscreenScreen({
    super.key,
    required this.lyrics,
    required this.initialActiveIndex,
    required this.activeIndexStream,
  });

  @override
  State<LyricsFullscreenScreen> createState() => _LyricsFullscreenScreenState();
}

class _LyricsFullscreenScreenState extends State<LyricsFullscreenScreen> {
  late int _activeIndex;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = [];
  StreamSubscription<int>? _lyricSubscription;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialActiveIndex;
    for (int i = 0; i < widget.lyrics.lines.length; i++) {
      _keys.add(GlobalKey());
    }
    
    _lyricSubscription = widget.activeIndexStream.listen((index) {
      if (mounted && index != _activeIndex) {
        setState(() {
          _activeIndex = index;
        });
        _scrollToActiveLine();
      }
    });

    // Initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLine();
    });
  }

  void _scrollToActiveLine() {
    if (_activeIndex < 0 || _activeIndex >= _keys.length) return;
    
    final context = _keys[_activeIndex].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                itemCount: widget.lyrics.lines.length,
                itemBuilder: (context, index) {
                  final line = widget.lyrics.lines[index];
                  final isActive = index == _activeIndex;
                  
                  return Padding(
                    key: _keys[index],
                    padding: const EdgeInsets.only(bottom: 30),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white38,
                        fontSize: isActive ? 32 : 26,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                        height: 1.3,
                        letterSpacing: -1.0,
                      ),
                      child: Text(line.text),
                    ),
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
  void dispose() {
    _lyricSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
