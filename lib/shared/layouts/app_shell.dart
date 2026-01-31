import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../widgets/mini_player.dart';
import '../widgets/floating_nav_bar.dart';

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
  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: Text('Search'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: Text('Library'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update AppNavigation when tab changes
    if (oldWidget.currentIndex != widget.currentIndex) {
      AppNavigation.setCurrentTab(widget.currentIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    AppNavigation.setCurrentTab(widget.currentIndex);
  }

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

  /// Handle back button - pop within tab first
  Future<bool> _handleBackPress() async {
    if (AppNavigation.canPop()) {
      AppNavigation.maybePop();
      return false; // Don't exit app
    }
    return true; // Allow app exit
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
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

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

  /// Content area with IndexedStack of nested navigators
  Widget _buildContent() {
    return IndexedStack(
      index: widget.currentIndex,
      children: List.generate(widget.screens.length, (index) {
        return _buildTabNavigator(index, widget.screens[index]);
      }),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main Content with nested navigators
          SafeArea(
            bottom: false,
            child: _buildContent(),
          ),

          // Floating Player & Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  ),
                  
                FloatingNavBar(
                  currentIndex: widget.currentIndex,
                  onTap: widget.onDestinationSelected,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search_rounded),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music_outlined),
                      activeIcon: Icon(Icons.library_music_rounded),
                      label: 'Library',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    
    return Scaffold(
      body: Row(
        children: [
          // Compact navigation rail
          NavigationRail(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onDestinationSelected,
            destinations: _railDestinations,
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
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    
    return Scaffold(
      body: Row(
        children: [
          // Navigation rail
          NavigationRail(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onDestinationSelected,
            destinations: _railDestinations,
            backgroundColor: surfaceColor,
            extended: true,
            minExtendedWidth: 200,
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
              child: _buildContent(),
            ),
          ),
        ],
      ),
      // Docked player at bottom for desktop
      bottomNavigationBar: widget.showMiniPlayer && widget.miniPlayerData != null
          ? MiniPlayer(
              trackTitle: widget.miniPlayerData!.trackTitle,
              artistName: widget.miniPlayerData!.artistName,
              artworkUrl: widget.miniPlayerData!.artworkUrl,
              isPlaying: widget.miniPlayerData!.isPlaying,
              progress: widget.miniPlayerData!.progress,
              onTap: widget.miniPlayerData!.onTap,
              onPlayPause: widget.miniPlayerData!.onPlayPause,
              onNext: widget.miniPlayerData!.onNext,
            )
          : null,
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
  });

  final String trackTitle;
  final String artistName;
  final String? artworkUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
}
