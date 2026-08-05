import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/navigation/app_tabs.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/desktop_player_bar.dart';
import '../widgets/now_playing_panel.dart';
import '../widgets/web_header.dart';

/// Responsive App Shell with Nested Navigation
///
/// Uses nested navigators per tab so navigation (nav bar + mini player)
/// stays visible on ALL screens - just like Spotify.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.screens,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.showMiniPlayer = false,
    this.miniPlayerData,
  });

  /// The root screens for each tab (Home, Search, Library, Profile)
  final List<Widget> screens;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showMiniPlayer;
  final MiniPlayerData? miniPlayerData;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _railDestinationsByTab = <int, NavigationRailDestination>{
    AppTabs.home: NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    AppTabs.uploads: NavigationRailDestination(
      icon: Icon(Icons.upload_file_outlined),
      selectedIcon: Icon(Icons.upload_file_rounded),
      label: Text('Feed'),
    ),
    AppTabs.search: NavigationRailDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: Text('Search'),
    ),
    AppTabs.library: NavigationRailDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: Text('Library'),
    ),
    AppTabs.profile: NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
    AppTabs.shopEntry: NavigationRailDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront_rounded),
      label: Text('Shop'),
    ),
  };

  static const _bottomNavItemsByTab = <int, BottomNavigationBarItem>{
    AppTabs.home: BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    AppTabs.uploads: BottomNavigationBarItem(
      icon: Icon(Icons.upload_file_outlined),
      activeIcon: Icon(Icons.upload_file_rounded),
      label: 'Feed',
    ),
    AppTabs.search: BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
    AppTabs.library: BottomNavigationBarItem(
      icon: Icon(Icons.library_music_outlined),
      activeIcon: Icon(Icons.library_music_rounded),
      label: 'Library',
    ),
    AppTabs.profile: BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
    AppTabs.shopEntry: BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      activeIcon: Icon(Icons.storefront_rounded),
      label: 'Shop',
    ),
  };

  /// Ordered tab indices for the nav bar/rail. The Feed (Reels) tab is
  /// omitted for under-13 accounts, since social/reel features aren't
  /// available to them.
  List<int> _visibleTabOrder(bool hideReelsTab) {
    return [
      AppTabs.home,
      if (!hideReelsTab) AppTabs.uploads,
      AppTabs.search,
      AppTabs.library,
      AppTabs.profile,
      AppTabs.shopEntry,
    ];
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update AppNavigation when tab changes
    if (oldWidget.currentIndex != widget.currentIndex) {
      AppNavigation.setCurrentTab(widget.currentIndex);
    }
  }

  // Cached navigator widgets - created lazily on first visit
  late final List<Widget?> _navigatorWidgets;
  // Tracks which tabs have been visited
  final Set<int> _visitedTabs = {0}; // Home tab (index 0) always visited

  // Web-specific state
  bool _isNowPlayingOpen = false;
  bool _isQueueTabOpen =
      false; // Track if Queue tab is selected in NowPlayingPanel

  // Track previous playing state to detect starts
  bool _wasPlaying = false;

  void _onPlayerChanged() {
    if (!mounted) return; // Guard against unmounted widget
    final player = context.read<PlayerProvider>();
    if (player.isPlaying && !_wasPlaying) {
      setState(() {
        _isNowPlayingOpen = true;
      });
    }
    _wasPlaying = player.isPlaying;
  }

  @override
  void initState() {
    super.initState();
    AppNavigation.setCurrentTab(widget.currentIndex);
    // Initialize with null placeholders — built lazily on first visit
    _navigatorWidgets = List<Widget?>.filled(widget.screens.length, null);
    // Build the initial tab immediately
    _navigatorWidgets[0] = _buildTabNavigator(0, widget.screens[0]);

    // Listen for playback start to auto-open panel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().addListener(_onPlayerChanged);
    });
  }

  @override
  void dispose() {
    try {
      context.read<PlayerProvider>().removeListener(_onPlayerChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Build a nested navigator for a tab

  /// Build a nested navigator for a tab
  Widget _buildTabNavigator(int tabIndex, Widget rootScreen) {
    return Navigator(
      key: AppNavigation.getNavigatorKey(tabIndex),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => rootScreen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (AppNavigation.canPop()) {
          AppNavigation.maybePop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

          if (isDesktop) {
            return _buildDesktopLayout(isDark);
          } else if (isTablet) {
            return _buildTabletLayout(isDark);
          } else {
            return _buildMobileLayout(isDark);
          }
        },
      ),
    );
  }

  /// Content area with lazy IndexedStack of nested navigators
  Widget _buildContent() {
    // Lazily build the current tab if not yet visited
    if (!_visitedTabs.contains(widget.currentIndex)) {
      _visitedTabs.add(widget.currentIndex);
      _navigatorWidgets[widget.currentIndex] = _buildTabNavigator(
        widget.currentIndex,
        widget.screens[widget.currentIndex],
      );
    }

    return IndexedStack(
      index: widget.currentIndex,
      children: List.generate(_navigatorWidgets.length, (i) {
        return _navigatorWidgets[i] ?? const SizedBox.shrink();
      }),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    final showMiniPlayer =
        widget.showMiniPlayer && widget.miniPlayerData != null;
    final isUnder13 = context.watch<ProfileProvider>().isUnder13;
    final tabOrder = _visibleTabOrder(isUnder13);
    final selectedPosition = tabOrder.indexOf(widget.currentIndex);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main Content with nested navigators
          Builder(
            builder: (ctx) {
              final mq = MediaQuery.of(ctx);
              const kNavBarHeight = 64.0;
              const kMiniPlayerHeight = 64.0;
              final extraBottom =
                  kNavBarHeight +
                  (showMiniPlayer ? kMiniPlayerHeight : 0.0) +
                  mq.padding.bottom;

              return MediaQuery(
                data: mq.copyWith(
                  padding: mq.padding.copyWith(bottom: extraBottom),
                  viewPadding: mq.viewPadding.copyWith(bottom: extraBottom),
                ),
                child: SafeArea(bottom: false, child: _buildContent()),
              );
            },
          ),

          // Floating Player & Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showMiniPlayer)
                  MiniPlayer(
                    trackTitle: widget.miniPlayerData!.trackTitle,
                    artistName: widget.miniPlayerData!.artistName,
                    artworkUrl: widget.miniPlayerData!.artworkUrl,
                    isPlaying: widget.miniPlayerData!.isPlaying,
                    progress: widget.miniPlayerData!.progress,
                    onTap: widget.miniPlayerData!.onTap,
                    onPlayPause: widget.miniPlayerData!.onPlayPause,
                    onNext: widget.miniPlayerData!.onNext,
                    onClose: widget.miniPlayerData!.onClose,
                  ),

                FloatingNavBar(
                  currentIndex: selectedPosition < 0 ? 0 : selectedPosition,
                  onTap: (position) {
                    final tabIndex = tabOrder[position];
                    if (tabIndex == AppTabs.shopEntry) {
                      // Shop icon — switch to shop mode
                      context.read<AppModeProvider>().enterShop();
                    } else {
                      widget.onDestinationSelected(tabIndex);
                    }
                  },
                  items: tabOrder
                      .map((tab) => _bottomNavItemsByTab[tab]!)
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final isUnder13 = context.watch<ProfileProvider>().isUnder13;
    final tabOrder = _visibleTabOrder(isUnder13);
    final selectedPosition = tabOrder.indexOf(widget.currentIndex);

    return Scaffold(
      body: Row(
        children: [
          // Compact navigation rail
          NavigationRail(
            selectedIndex: selectedPosition < 0 ? 0 : selectedPosition,
            onDestinationSelected: (position) {
              final tabIndex = tabOrder[position];
              if (tabIndex == AppTabs.shopEntry) {
                context.read<AppModeProvider>().enterShop();
              } else {
                widget.onDestinationSelected(tabIndex);
              }
            },
            destinations: tabOrder
                .map((tab) => _railDestinationsByTab[tab]!)
                .toList(),
            backgroundColor: surfaceColor,
            labelType: NavigationRailLabelType.all,
          ),

          // Divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),

          // Content with nested navigators
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(child: _buildContent()),
                  if (widget.showMiniPlayer && widget.miniPlayerData != null)
                    MiniPlayer(
                      trackTitle: widget.miniPlayerData!.trackTitle,
                      artistName: widget.miniPlayerData!.artistName,
                      artworkUrl: widget.miniPlayerData!.artworkUrl,
                      isPlaying: widget.miniPlayerData!.isPlaying,
                      progress: widget.miniPlayerData!.progress,
                      onTap: widget.miniPlayerData!.onTap,
                      onPlayPause: widget.miniPlayerData!.onPlayPause,
                      onNext: widget.miniPlayerData!.onNext,
                      onClose: widget.miniPlayerData!.onClose,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final hasMedia = player.hasMedia;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : AppColors.lightBg,
          body: Column(
            children: [
              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Main content + header
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF121212)
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            WebHeader(
                              currentTabIndex: widget.currentIndex,
                              onNavigateTo: widget.onDestinationSelected,
                            ),

                            // Content with nested navigators
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                                child: _buildContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Now Playing Panel (only when open, has media, and UI is enabled)
                    if (widget.showMiniPlayer && _isNowPlayingOpen && hasMedia)
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF121212)
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: NowPlayingPanel(
                          onClose: () {
                            setState(() => _isNowPlayingOpen = false);
                          },
                          onTabChanged: (isQueueOpen) {
                            setState(() => _isQueueTabOpen = isQueueOpen);
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Player Bar
              DesktopPlayerBar(
                isNowPlayingOpen: _isNowPlayingOpen,
                isQueueTabOpen: _isQueueTabOpen,
                onNowPlayingToggle: () {
                  setState(() => _isNowPlayingOpen = !_isNowPlayingOpen);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Data class for mini player
class MiniPlayerData {
  const MiniPlayerData({
    required this.trackTitle,
    required this.artistName,
    this.artworkUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.onTap,
    this.onPlayPause,
    this.onNext,
    this.onClose,
  });

  final String trackTitle;
  final String artistName;
  final String? artworkUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onClose;
}
