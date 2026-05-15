import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-safe network image widget.
///
/// On web, this uses `Image.network` (browser pipeline).
/// On other platforms, this keeps `CachedNetworkImage` behavior.
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackImageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.placeholder,
    this.errorChild,
    this.filterQuality = FilterQuality.low,
  });

  final String imageUrl;
  final String? fallbackImageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final Widget? placeholder;
  final Widget? errorChild;
  final FilterQuality filterQuality;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  late String _currentUrl;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _resetUrl();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackImageUrl != widget.fallbackImageUrl) {
      _resetUrl();
    }
  }

  void _resetUrl() {
    _currentUrl = widget.imageUrl.trim();
    _usingFallback = false;
  }

  bool _switchToFallbackIfPossible() {
    final fallback = widget.fallbackImageUrl?.trim() ?? '';
    if (_usingFallback || fallback.isEmpty || fallback == _currentUrl) {
      return false;
    }
    setState(() {
      _usingFallback = true;
      _currentUrl = fallback;
    });
    return true;
  }

  Widget _placeholder() => widget.placeholder ?? const SizedBox.shrink();

  Widget _error() => widget.errorChild ?? _placeholder();

  @override
  Widget build(BuildContext context) {
    if (_currentUrl.isEmpty) {
      return _error();
    }

    if (kIsWeb) {
      return Image.network(
        _currentUrl,
        key: ValueKey(_currentUrl),
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
        errorBuilder: (_, __, ___) {
          if (_switchToFallbackIfPossible()) {
            return _placeholder();
          }
          return _error();
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey(_currentUrl),
      imageUrl: _currentUrl,
      fit: widget.fit,
      alignment: widget.alignment,
      memCacheWidth: widget.memCacheWidth,
      filterQuality: widget.filterQuality,
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        if (_switchToFallbackIfPossible()) {
          return _placeholder();
        }
        return _error();
      },
    );
  }
}
