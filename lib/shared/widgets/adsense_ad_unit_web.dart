import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/services/ads_service.dart';
import '../../core/services/adsense_config.dart';

/// The `window.veenaAdsense` bridge defined in `web/index.html`.
@JS('veenaAdsense')
external _AdSenseBridge? get _bridge;

extension type _AdSenseBridge._(JSObject _) implements JSObject {
  /// Queues a fill request for the most recently added, still-empty `<ins>`.
  external bool requestAd();

  /// True when the loader script never made it — usually an ad blocker.
  external bool get scriptFailed;

  /// False until Google's script has actually run.
  external bool get scriptLoaded;

  /// Publisher id the loader script in index.html was started with.
  external String loaderClient();
}

/// A real AdSense display unit, mounted into the page as a Flutter platform
/// view.
///
/// Flutter web paints into a canvas, so there is no markup for AdSense to
/// attach to on its own — Auto ads find nothing to fill. This widget creates
/// the `<ins class="adsbygoogle">` element itself, hands it to Flutter as a
/// platform view (which keeps it in the light DOM where Google's script can
/// measure it), and pushes a fill request once it is attached and sized.
///
/// Renders nothing when the slot cannot be filled, so the layout never keeps a
/// blank rectangle: no publisher/slot id configured, ads switched off for a
/// subscriber, a blocked script, or AdSense reporting the slot as unfilled.
class AdSenseAdUnit extends StatefulWidget {
  const AdSenseAdUnit({
    super.key,
    this.height = 50,
    this.maxHeight,
    this.margin,
    this.format = AdSenseFormat.display,
    this.slot,
  });

  /// Height reserved before the ad arrives. A display unit is served at exactly
  /// this height; an in-feed unit treats it as a starting point.
  final double height;

  /// Ceiling for an in-feed unit that comes back taller than [height]. Null
  /// pins the slot to [height], clipping anything larger.
  final double? maxHeight;

  final EdgeInsetsGeometry? margin;

  /// Which of the configured ad units to request.
  final AdSenseFormat format;

  /// Overrides the configured slot for this placement.
  final String? slot;

  @override
  State<AdSenseAdUnit> createState() => _AdSenseAdUnitState();
}

enum _AdState { pending, filled, unfilled }

class _AdSenseAdUnitState extends State<AdSenseAdUnit> {
  /// AdSense will not fill anything narrower than this.
  static const double _minWidth = 120;

  /// A push that never gets a verdict is retried this many times before the
  /// slot is written off for this session.
  static const int _maxRetries = 2;

  /// Minimum time after app start before the first ad request can fire. This
  /// ensures the Flutter app has rendered real publisher content before any ad
  /// slot is filled — requesting during the splash screen would show ads on a
  /// screen without content, which is an AdSense policy violation.
  static const Duration _startupGracePeriod = Duration(seconds: 3);

  static final DateTime _appStartTime = DateTime.now();

  /// Returns true once enough time has elapsed since app start for the main
  /// content to be on screen.
  static bool get _pastStartupGrace =>
      DateTime.now().difference(_appStartTime) >= _startupGracePeriod;

  static int _instanceCounter = 0;

  static String _nextViewType() =>
      'veena-adsense-${DateTime.now().microsecondsSinceEpoch}-${_instanceCounter++}';

  String _viewType = _nextViewType();

  web.HTMLElement? _hostElement;
  web.HTMLElement? _insElement;
  double? _renderedWidth;
  _AdState _state = _AdState.pending;
  Timer? _statusPoll;
  Timer? _retryTimer;
  bool _requested = false;
  bool _warnedTooNarrow = false;
  int _retries = 0;

  /// Height the widget currently reserves. Only an in-feed unit changes it,
  /// once the served ad reports its real height.
  double? _adoptedHeight;

  String get _slotId => widget.slot ?? AdSenseConfig.slotFor(widget.format);

  bool get _isFluid => widget.format == AdSenseFormat.inFeed;

  double get _reservedHeight => _adoptedHeight ?? widget.height;

  @override
  void initState() {
    super.initState();
    AdSenseConfig.warnIfMisconfigured();
  }

  @override
  void dispose() {
    _statusPoll?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Builds the ad markup once, at the width Flutter has laid out for it.
  ///
  /// Both the wrapper and the `<ins>` get concrete pixel sizes. AdSense decides
  /// what to serve by measuring the element and its parent, and Flutter's
  /// platform-view host carries no width of its own — left to infer, AdSense
  /// reads a few dozen pixels and rejects the request with
  /// "No slot size for availableWidth=…".
  void _ensureElement(double width) {
    if (_hostElement != null) return;

    final w = width.floor();
    final h = _reservedHeight.floor();

    final host = web.document.createElement('div') as web.HTMLElement;
    host.style
      ..display = 'block'
      ..width = '${w}px'
      ..height = '${h}px'
      ..overflow = 'hidden';

    final ins = web.document.createElement('ins') as web.HTMLElement;
    ins.className = 'adsbygoogle';
    ins.style
      ..display = 'block'
      ..width = '${w}px'
      ..overflow = 'hidden';
    ins.setAttribute('data-ad-client', AdSenseConfig.client);
    ins.setAttribute('data-ad-slot', _slotId);

    if (_isFluid) {
      // An in-feed unit chooses its own height from the layout key, so pinning
      // one would either crop the creative or leave dead space. The widget
      // adopts whatever height comes back instead — see [_adoptServedHeight].
      ins.setAttribute('data-ad-format', 'fluid');
      ins.setAttribute('data-ad-layout-key', AdSenseConfig.inFeedLayoutKey);
    } else {
      // Deliberately no `data-ad-format` here: that switches AdSense into
      // responsive mode, where it picks its own height and overflows the box
      // Flutter reserved. Omitted, it honours the explicit style below.
      ins.style.height = '${h}px';
      ins.setAttribute('data-full-width-responsive', 'false');
    }

    host.append(ins);

    _hostElement = host;
    _insElement = ins;
    _renderedWidth = width;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _hostElement!,
    );

    debugPrint('[AdSense] slot $_slotId mounted at ${w}x$h');
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestAd());
  }

  void _resize(double width) {
    final w = width.floor();
    _renderedWidth = width;
    _hostElement?.style.width = '${w}px';
    _insElement?.style.width = '${w}px';
  }

  /// Waits until the slot is genuinely on screen and measurable.
  ///
  /// A slot that is not being composited — the carousel card while its page is
  /// off to the side, a player surface behind another route — measures 0px wide
  /// even though it is attached to the document. That is a *not yet* state, not
  /// a too-small placement: the same element measures full width the moment its
  /// page slides in. Requesting an ad for it would either be rejected ("No slot
  /// size for availableWidth=0") or burn an impression nobody can see, so the
  /// request simply waits.
  ///
  /// Returns false when the slot never became viewable, leaving the widget
  /// pending rather than collapsing it — a later rebuild gets another go.
  Future<bool> _waitUntilOnScreen(web.HTMLElement ins) async {
    const poll = Duration(milliseconds: 300);
    const limit = Duration(seconds: 90);
    var waited = Duration.zero;
    var sawLayout = false;

    while (waited < limit) {
      if (!mounted) return false;

      if (ins.isConnected && web.document.visibilityState == 'visible') {
        final rect = ins.getBoundingClientRect();
        final laidOut = rect.width > 0 && rect.height > 0;
        if (laidOut) sawLayout = true;

        final onScreen =
            laidOut &&
            rect.right > 0 &&
            rect.bottom > 0 &&
            rect.left < web.window.innerWidth &&
            rect.top < web.window.innerHeight;

        if (onScreen) {
          // Laid out, on screen, and still too narrow for any creative: this
          // placement genuinely cannot host an ad. Collapse it for good.
          if (rect.width < _minWidth) {
            debugPrint(
              '[AdSense] slot $_slotId placement is only '
              '${rect.width.round()}px wide (AdSense needs '
              '≥${_minWidth.round()}) — hiding it',
            );
            _markUnfilled();
            return false;
          }
          return true;
        }
      }

      await Future<void>.delayed(poll);
      waited += poll;
    }

    debugPrint(
      '[AdSense] slot $_slotId never came on screen '
      '(${sawLayout ? 'laid out but scrolled away' : 'never composited'}) — '
      'still pending',
    );
    return false;
  }

  /// Asks AdSense to fill the slot, once it is really on screen.
  ///
  /// Flutter attaches the platform view after the factory returns, and pushing
  /// before that produces an ad sized against a detached node.
  Future<void> _requestAd() async {
    if (_requested || !mounted) return;

    // Wait for the startup grace period before the very first ad request.
    // This ensures Flutter has rendered real publisher content (past the
    // splash screen) before any ad fills, avoiding AdSense policy violations.
    if (!_pastStartupGrace) {
      final remaining = _startupGracePeriod -
          DateTime.now().difference(_appStartTime);
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
        if (!mounted) return;
      }
    }

    final ins = _insElement;
    if (ins == null) return;

    // Nothing is requested until the slot is on screen in a foreground tab —
    // both for a valid measurement and because an impression nobody could see
    // counts as invalid traffic.
    if (!await _waitUntilOnScreen(ins)) return;

    final bridge = _bridge;
    if (bridge == null) {
      debugPrint(
        '[AdSense] window.veenaAdsense missing — is web/index.html current?',
      );
      _markUnfilled();
      return;
    }

    // Give the loader a fair chance before giving up: on a cold, slow
    // connection the script can take seconds, and a push made against a script
    // that never arrives is a slot that stays blank forever.
    for (var attempt = 0; attempt < 50 && !bridge.scriptLoaded; attempt++) {
      if (!mounted) return;
      if (bridge.scriptFailed) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;

    if (bridge.scriptFailed) {
      debugPrint('[AdSense] loader script blocked (ad blocker?)');
      _markUnfilled();
      return;
    }

    if (!bridge.scriptLoaded) {
      debugPrint('[AdSense] loader script still not ready — retrying later');
      _scheduleRetry();
      return;
    }

    // A publisher id that disagrees with the loader tag gets every request
    // rejected, with nothing in the console to explain it.
    final loaderClient = bridge.loaderClient();
    if (loaderClient.isNotEmpty && loaderClient != AdSenseConfig.client) {
      debugPrint(
        '[AdSense] publisher id mismatch: web/index.html loads "$loaderClient" '
        'but ADSENSE_CLIENT is "${AdSenseConfig.client}". Fix one of them — '
        'AdSense will not fill a slot whose client differs from the loader.',
      );
      _markUnfilled();
      return;
    }

    _requested = true;
    final pushed = bridge.requestAd();
    debugPrint('[AdSense] requested slot $_slotId (queued=$pushed)');

    if (!pushed) {
      // The push threw (usually a transient sizing complaint) — the element is
      // spent, so a retry has to start from a fresh one.
      _scheduleRetry();
      return;
    }

    _watchFillStatus();
  }

  /// Rebuilds the slot from scratch after an environmental failure (loader not
  /// ready, push rejected). Bounded, and never used for a genuine `unfilled`
  /// verdict — re-requesting ads Google declined to fill is a policy problem,
  /// not a bug fix.
  void _scheduleRetry() {
    if (_retries >= _maxRetries) {
      debugPrint('[AdSense] slot $_slotId gave up after $_retries retries');
      _markUnfilled();
      return;
    }

    _retries++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 3 * _retries), () {
      if (!mounted) return;
      setState(() {
        _hostElement = null;
        _insElement = null;
        _renderedWidth = null;
        _requested = false;
        _viewType = _nextViewType();
      });
    });
  }

  /// Google stamps `data-ad-status` on the `<ins>` once it decides.
  void _watchFillStatus() {
    var elapsed = Duration.zero;
    const tick = Duration(milliseconds: 400);

    _statusPoll?.cancel();
    _statusPoll = Timer.periodic(tick, (timer) {
      elapsed += tick;
      final status = _insElement?.getAttribute('data-ad-status');

      if (status == 'filled') {
        timer.cancel();
        if (mounted && _state != _AdState.filled) {
          setState(() => _state = _AdState.filled);
        }
        _adoptServedHeight();
        return;
      }

      if (status == 'unfilled') {
        timer.cancel();
        debugPrint('[AdSense] slot $_slotId came back unfilled');
        _markUnfilled();
        return;
      }

      // No verdict at all means the request never really left the page — that
      // is worth another attempt, unlike an explicit "unfilled".
      if (elapsed >= const Duration(seconds: 15)) {
        timer.cancel();
        debugPrint('[AdSense] slot $_slotId timed out without a fill status');
        _scheduleRetry();
      }
    });
  }

  /// Grows the reserved box to the height AdSense actually served.
  ///
  /// Only in-feed units need this: their height comes from the layout key, so
  /// the widget cannot know it up front. Bounded by [AdSenseAdUnit.maxHeight]
  /// so a tall creative cannot blow up the surrounding layout — and the ad is
  /// never shrunk below what it needs, which would crop it.
  void _adoptServedHeight() {
    if (!_isFluid || !mounted) return;

    final ceiling = widget.maxHeight;
    if (ceiling == null) return;

    // The creative lands in a child iframe a beat after the fill verdict.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final served = _insElement?.getBoundingClientRect().height ?? 0;
      if (served <= 0) return;

      final target = served.clamp(widget.height, ceiling);
      if ((target - _reservedHeight).abs() < 2) return;

      debugPrint(
        '[AdSense] in-feed slot $_slotId served at ${served.round()}px, '
        'reserving ${target.round()}px',
      );
      setState(() => _adoptedHeight = target.toDouble());
      _hostElement?.style.height = '${target.floor()}px';
    });
  }

  void _markUnfilled() {
    _statusPoll?.cancel();
    if (mounted && _state != _AdState.unfilled) {
      setState(() => _state = _AdState.unfilled);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsService.canShowAds || _slotId.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_state == _AdState.unfilled) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        if (available < _minWidth) {
          if (!_warnedTooNarrow) {
            _warnedTooNarrow = true;
            debugPrint(
              '[AdSense] slot $_slotId skipped: placement is only '
              '${available.round()}px wide (AdSense needs ≥${_minWidth.round()})',
            );
          }
          return const SizedBox.shrink();
        }

        _ensureElement(available);

        // Keep the element in step with later resizes; the already-served ad
        // keeps its own size, but a not-yet-filled slot gets the real width.
        if (_renderedWidth != null && (available - _renderedWidth!).abs() > 1) {
          _resize(available);
        }

        return Container(
          margin: widget.margin,
          width: available,
          height: _reservedHeight,
          alignment: Alignment.center,
          child: HtmlElementView(viewType: _viewType),
        );
      },
    );
  }
}
