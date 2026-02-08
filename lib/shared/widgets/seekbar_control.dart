import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SeekbarControl extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Duration currentPosition;
  final ValueChanged<double> onSeek;
  final bool isWeb;

  const SeekbarControl({
    super.key,
    required this.progress,
    required this.duration,
    required this.currentPosition,
    required this.onSeek,
    this.isWeb = false,
  });

  @override
  State<SeekbarControl> createState() => _SeekbarControlState();
}

class _SeekbarControlState extends State<SeekbarControl> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final showValue = _isDragging ? _dragValue : widget.progress;
    
    // Calculate display time based on drag value if dragging, otherwise use current position
    final displayTime = _isDragging 
        ? Duration(milliseconds: (widget.duration.inMilliseconds * _dragValue).toInt())
        : widget.currentPosition;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.isWeb ? AppColors.primary : Colors.white,
            inactiveTrackColor: widget.isWeb ? Colors.white12 : Colors.white24,
            thumbColor: Colors.white,
            overlayColor: widget.isWeb ? AppColors.primary.withOpacity(0.2) : null,
            overlayShape: widget.isWeb ? null : SliderComponentShape.noOverlay,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: widget.isWeb ? 7 : 6, 
              pressedElevation: 10
            ),
            trackHeight: 4,
          ),
          child: Slider(
            value: showValue.clamp(0.0, 1.0),
            onChanged: (value) {
              setState(() {
                _isDragging = true;
                _dragValue = value;
              });
            },
            onChangeEnd: (value) {
              setState(() {
                _isDragging = false;
                _dragValue = value;
              });
              widget.onSeek(value);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isWeb ? 16 : 24, vertical: widget.isWeb ? 0 : 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(displayTime), 
                style: TextStyle(
                  color: widget.isWeb ? Colors.white54 : Colors.white60,
                  fontSize: 12, 
                  fontWeight: FontWeight.w600
                ),
              ),
              Text(
                _formatDuration(widget.duration), 
                style: TextStyle(
                  color: widget.isWeb ? Colors.white54 : Colors.white60, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
