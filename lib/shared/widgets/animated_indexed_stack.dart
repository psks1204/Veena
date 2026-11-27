import 'package:flutter/widgets.dart';

/// An [IndexedStack] whose selected child fades in with a slight rise each
/// time [index] changes (and when the stack first appears).
///
/// Kept deliberately cheap: only the newly selected child is painted, so a
/// switch is one short opacity + offset animation over a single screen — no
/// cross-fade that would have to draw two tabs at once — and every child keeps
/// its state, exactly like a plain IndexedStack. Honours the system's "remove
/// animations" setting.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  // Starts faint rather than fully transparent, so a switch never shows an
  // empty frame between tabs (which reads as a flicker) — the new tab is
  // there at once and just settles in.
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.2,
    end: 1,
  ).animate(_progress);
  // About 10px on a phone: enough to read as movement, too little to jar.
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(_progress);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index == widget.index) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
