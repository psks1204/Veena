import 'package:flutter/widgets.dart';

import '../../core/services/adsense_config.dart';

/// Non-web builds have no AdSense — mobile serves AdMob instead.
class AdSenseAdUnit extends StatelessWidget {
  const AdSenseAdUnit({
    super.key,
    this.height = 50,
    this.maxHeight,
    this.margin,
    this.format = AdSenseFormat.display,
    this.slot,
  });

  final double height;
  final double? maxHeight;
  final EdgeInsetsGeometry? margin;
  final AdSenseFormat format;
  final String? slot;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
