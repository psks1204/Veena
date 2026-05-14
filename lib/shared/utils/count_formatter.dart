String formatCompactCount(int value) {
  final abs = value.abs();

  if (abs >= 1000000000) {
    return '${_formatScaled(value / 1000000000)}B';
  }
  if (abs >= 1000000) {
    return '${_formatScaled(value / 1000000)}M';
  }
  if (abs >= 1000) {
    return '${_formatScaled(value / 1000)}K';
  }
  return value.toString();
}

String _formatScaled(num value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
