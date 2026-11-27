import 'package:flutter/widgets.dart';

/// Lets a screen that plays video in place (the reel feeds) play only while
/// the user can actually see it.
///
/// The screen counts as on screen when all of these hold:
///  * its tab is the selected one — `AppShell` switches tickers off for the
///    tabs it keeps alive in the background;
///  * no full-screen page covers it, whether pushed in its own tab or over the
///    whole app — `Navigator` switches tickers off for covered routes;
///  * the app is in the foreground.
///
/// Whenever that changes, [onPlaybackAllowedChanged] is called: pause
/// everything on `false`, resume the visible reel on `true`. Check
/// [playbackAllowed] before starting playback that is not a direct response
/// to a tap — e.g. when a video finishes loading after the user has already
/// moved to another screen.
mixin OnScreenPlaybackMixin<T extends StatefulWidget> on State<T> {
  bool _tickerEnabled = true;
  bool _appInForeground = true;
  bool _lastReported = true;
  bool _reportScheduled = false;
  AppLifecycleListener? _lifecycleListener;

  /// Whether this screen is visible and may play media right now.
  bool get playbackAllowed => mounted && _tickerEnabled && _appInForeground;

  /// Called when [playbackAllowed] flips.
  void onPlaybackAllowedChanged(bool allowed);

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appInForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _lastReported = _appInForeground;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        _appInForeground = state == AppLifecycleState.resumed;
        // Lifecycle events arrive outside a frame (and none are drawn while
        // the app is in the background), so report right away.
        _report();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.of(context);
    if (enabled == _tickerEnabled) return;
    _tickerEnabled = enabled;
    // This runs mid-build; starting or stopping a video notifies widgets
    // listening to it, so wait for the frame to finish.
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      _report();
    });
  }

  void _report() {
    if (!mounted) return;
    final allowed = playbackAllowed;
    if (allowed == _lastReported) return;
    _lastReported = allowed;
    onPlaybackAllowedChanged(allowed);
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
