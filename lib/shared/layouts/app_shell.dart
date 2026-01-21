import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/mini_player.dart';
import '../widgets/floating_nav_bar.dart';

/// Responsive App Shell
/// 
/// Provides navigation structure that adapts across devices:
/// - Mobile: Bottom navigation bar
/// - Tablet: Two-column with persistent mini-player
/// - Desktop: Side navigation rail
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.showMiniPlayer = false,
    this.miniPlayerData,
  });

  final Widget child;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: width >= 1200
        // Tablet: width >= 600
        // Mobile: width < 600
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
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      extendBody: true, // Allow body to go behind the floating nav
      body: Stack(
        children: [
          // Main Content
          widget.child,

          // Floating Player & Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showMiniPlayer && widget.miniPlayerData != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MiniPlayer(
                      trackTitle: widget.miniPlayerData!.trackTitle,
                      artistName: widget.miniPlayerData!.artistName,
                      artworkUrl: widget.miniPlayerData!.artworkUrl,
                      isPlaying: widget.miniPlayerData!.isPlaying,
                      progress: widget.miniPlayerData!.progress,
                      onTap: widget.miniPlayerData!.onTap,
                      onPlayPause: widget.miniPlayerData!.onPlayPause,
                      onNext: widget.miniPlayerData!.onNext,
                    ),
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
          
          // Content
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.child),
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
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    
    return Scaffold(
      body: Row(
        children: [
          // Extended navigation rail with logo
          Container(
            width: 240,
            color: surfaceColor,
            child: Column(
              children: [
                // Logo area
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Veena',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation items
                Expanded(
                  child: NavigationRail(
                    selectedIndex: widget.currentIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    destinations: _railDestinations,
                    backgroundColor: Colors.transparent,
                    labelType: NavigationRailLabelType.none,
                    extended: true,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.black.withOpacity(0.05),
          ),
          
          // Content
          Expanded(
            child: widget.child,
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
