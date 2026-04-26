import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/app_mode_provider.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/desktop_player_bar.dart';
import '../widgets/mini_player.dart';
import 'app_shell.dart' show MiniPlayerData;

/// Shop Shell
///
/// Wraps the shop's 4 tabs (Home, Orders, Wishlist, Cart) with its own
/// navigation. On mobile: FloatingNavBar with a "← Music" back item.
/// On desktop: sidebar + DesktopPlayerBar (music keeps playing).
///
/// Music playback continues across modes — PlayerProvider is shared.
class ShopShell extends StatefulWidget {
  const ShopShell({
    super.key,
    required this.screens,
    required this.miniPlayerData,
  });

  /// Screens for shop tabs: [ShopHome, Orders, Wishlist, Cart]
  final List<Widget> screens;
  final MiniPlayerData? miniPlayerData;

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  late final List<Widget> _navigators;

  @override
  void initState() {
    super.initState();
    _navigators = List.generate(
      widget.screens.length,
      (i) => _buildNavigator(i, widget.screens[i]),
    );
  }

  Widget _buildNavigator(int tabIndex, Widget root) {
    // Shop tabs use indices 5-8 in AppNavigation
    return Navigator(
      key: AppNavigation.getNavigatorKey(tabIndex + 5),
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        if (isDesktop) return _buildDesktop(context);
        if (isTablet) return _buildTablet(context);
        return _buildMobile(context);
      },
    );
  }

  Widget _buildContent(int index) {
    return IndexedStack(index: index, children: _navigators);
  }

  Widget _buildMobile(BuildContext context) {
    final appMode = context.watch<AppModeProvider>();
    final tabIndex = appMode.shopTabIndex;
    final player = context.watch<PlayerProvider>();
    final showPlayer = player.hasMedia;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<AppModeProvider>().exitShop();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Override MediaQuery so nested SafeArea / Scaffold.bottomNavigationBar
            // know how tall the floating nav bar is and stay clear of it.
            Builder(
              builder: (ctx) {
                final mq = MediaQuery.of(ctx);
                const kNavBarHeight = 64.0; // FloatingNavBar approximate height
                const kMiniPlayerHeight = 64.0;
                final extraBottom =
                    kNavBarHeight +
                    (showPlayer ? kMiniPlayerHeight : 0.0) +
                    mq.padding.bottom;
                return MediaQuery(
                  data: mq.copyWith(
                    padding: mq.padding.copyWith(bottom: extraBottom),
                    viewPadding: mq.viewPadding.copyWith(bottom: extraBottom),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: _buildContent(tabIndex),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPlayer && widget.miniPlayerData != null)
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
                    currentIndex: tabIndex,
                    onTap: (index) {
                      if (index == 4) {
                        // ← Music: exit shop
                        context.read<AppModeProvider>().exitShop();
                      } else {
                        context.read<AppModeProvider>().setShopTab(index);
                      }
                    },
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.storefront_outlined),
                        activeIcon: Icon(Icons.storefront_rounded),
                        label: 'Store',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long_outlined),
                        activeIcon: Icon(Icons.receipt_long_rounded),
                        label: 'Orders',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite_border_rounded),
                        activeIcon: Icon(Icons.favorite_rounded),
                        label: 'Wishlist',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.shopping_cart_outlined),
                        activeIcon: Icon(Icons.shopping_cart_rounded),
                        label: 'Cart',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.music_note_outlined),
                        activeIcon: Icon(Icons.music_note_rounded),
                        label: '← Music',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appMode = context.watch<AppModeProvider>();
    final tabIndex = appMode.shopTabIndex;
    final player = context.watch<PlayerProvider>();
    final showPlayer = player.hasMedia;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<AppModeProvider>().exitShop();
      },
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tabIndex,
              onDestinationSelected: (index) {
                if (index == 4) {
                  context.read<AppModeProvider>().exitShop();
                } else {
                  context.read<AppModeProvider>().setShopTab(index);
                }
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: Text('Store'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: Text('Wishlist'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart_rounded),
                  label: Text('Cart'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note_rounded),
                  label: Text('← Music'),
                ),
              ],
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              labelType: NavigationRailLabelType.all,
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(child: _buildContent(tabIndex)),
                    if (showPlayer && widget.miniPlayerData != null)
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
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appMode = context.watch<AppModeProvider>();
    final tabIndex = appMode.shopTabIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<AppModeProvider>().exitShop();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : AppColors.lightBg,
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF121212)
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Shop top header bar
                          _ShopDesktopHeader(
                            tabIndex: tabIndex,
                            onTabSelected: (i) =>
                                context.read<AppModeProvider>().setShopTab(i),
                            onExitShop: () =>
                                context.read<AppModeProvider>().exitShop(),
                            isDark: isDark,
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                              child: _buildContent(tabIndex),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DesktopPlayerBar(
              isNowPlayingOpen: false,
              isQueueTabOpen: false,
              onNowPlayingToggle: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop top bar for the Shop shell
class _ShopDesktopHeader extends StatelessWidget {
  const _ShopDesktopHeader({
    required this.tabIndex,
    required this.onTabSelected,
    required this.onExitShop,
    required this.isDark,
  });

  final int tabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onExitShop;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back to music
          TextButton.icon(
            onPressed: onExitShop,
            icon: const Icon(Icons.music_note_rounded, size: 18),
            label: const Text('← Music'),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? Colors.white54
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 24),
          Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Shop',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 32),
          // Tab links
          _tab(context, 0, 'Store', Icons.storefront_outlined),
          _tab(context, 1, 'Orders', Icons.receipt_long_outlined),
          _tab(context, 2, 'Wishlist', Icons.favorite_border_rounded),
          _tab(context, 3, 'Cart', Icons.shopping_cart_outlined),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int index, String label, IconData icon) {
    final isActive = tabIndex == index;
    final color = isActive
        ? AppColors.primary
        : (isDark ? Colors.white54 : AppColors.lightTextSecondary);
    return TextButton.icon(
      onPressed: () => onTabSelected(index),
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
