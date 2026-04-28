import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/app_tabs.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../features/auth/services/auth_service.dart';
import '../../core/providers/profile_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/notifications/presentation/widgets/notification_detail_dialog.dart';

/// Spotify-style Web Header Bar
///
/// Top header with navigation links (Home, Search, Library) and user profile.
class WebHeader extends StatefulWidget {
  const WebHeader({
    super.key,
    required this.currentTabIndex,
    required this.onNavigateTo,
  });

  final int currentTabIndex;
  final ValueChanged<int> onNavigateTo;

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _notificationOverlayEntry;
  bool _showUserMenu = false;
  bool _showNotificationMenu = false;
  final GlobalKey _userMenuKey = GlobalKey();
  final GlobalKey _notificationMenuKey = GlobalKey();
  final LayerLink _notificationLayerLink = LayerLink();

  @override
  void dispose() {
    _overlayEntry?.remove();
    _notificationOverlayEntry?.remove();
    super.dispose();
  }

  void _toggleUserMenu() {
    if (_showNotificationMenu) _toggleNotificationMenu();
    if (_showUserMenu) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _showUserMenu = false);
    } else {
      setState(() => _showUserMenu = true);
      _overlayEntry = _createUserMenuOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _toggleNotificationMenu() {
    if (_showUserMenu) _toggleUserMenu();
    if (_showNotificationMenu) {
      _notificationOverlayEntry?.remove();
      _notificationOverlayEntry = null;
      setState(() => _showNotificationMenu = false);
    } else {
      setState(() => _showNotificationMenu = true);
      _notificationOverlayEntry = _createNotificationOverlay();
      Overlay.of(context).insert(_notificationOverlayEntry!);
      // Refresh notifications when opening
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    }
  }

  OverlayEntry _createNotificationOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleNotificationMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _notificationLayerLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.transparent,
              child: _buildNotificationMenu(),
            ),
          ),
        ],
      ),
    );
  }

  OverlayEntry _createUserMenuOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleUserMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu
          CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: Material(color: Colors.transparent, child: _buildUserMenu()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // Home Logo Button
          InkWell(
            onTap: () => widget.onNavigateTo(AppTabs.home), // Go to Home
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(right: 32),
              width: 140,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                isDark
                    ? 'assets/images/branding_dark.png'
                    : 'assets/images/branding_light.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),

          // Navigation Links
          _buildNavLink(AppTabs.home, 'Home', Icons.home_filled, isDark),
          const SizedBox(width: 8),
          _buildNavLink(
            AppTabs.uploads,
            'Feed',
            Icons.upload_file_rounded,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildNavLink(AppTabs.search, 'Search', Icons.search_rounded, isDark),
          const SizedBox(width: 8),
          _buildNavLink(
            AppTabs.library,
            'Your Library',
            Icons.library_music_rounded,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildShopNavLink(isDark),

          const Spacer(),

          // Right side actions
          _buildRightActions(isDark),
        ],
      ),
    );
  }

  Widget _buildShopNavLink(bool isDark) {
    final inactiveColor = isDark
        ? Colors.white54
        : AppColors.lightTextSecondary;
    return TextButton.icon(
      onPressed: () => context.read<AppModeProvider>().enterShop(),
      style: TextButton.styleFrom(
        foregroundColor: inactiveColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(Icons.storefront_outlined, size: 22, color: inactiveColor),
      label: Text(
        'Shop',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: inactiveColor,
        ),
      ),
    );
  }

  Widget _buildNavLink(int index, String label, IconData icon, bool isDark) {
    final isActive = widget.currentTabIndex == index;
    final baseColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final inactiveColor = isDark
        ? Colors.white54
        : AppColors.lightTextSecondary;
    final color = isActive ? baseColor : inactiveColor;

    return TextButton.icon(
      onPressed: () => widget.onNavigateTo(index),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 22, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRightActions(bool isDark) {
    final profileProvider = context.watch<ProfileProvider>();
    final authService = context.watch<AuthService>();
    final profile = profileProvider.profile;

    // Fallback logic
    final pName = profile?.name;
    final userName = (pName != null && pName.isNotEmpty)
        ? pName
        : (authService.userName ?? 'User');

    final pPhoto = profile?.photoUrl;
    final userPicture = (pPhoto != null && pPhoto.isNotEmpty)
        ? pPhoto
        : authService.userPicture;

    // Initials logic
    String userInitials = 'U';
    if (userName != 'User') {
      final parts = userName.split(' ');
      if (parts.length >= 2) {
        userInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (userName.isNotEmpty) {
        userInitials = userName[0].toUpperCase();
      }
    } else if (profile?.initials != null) {
      userInitials = profile!.initials;
    } else if (authService.userInitials.isNotEmpty) {
      userInitials = authService.userInitials;
    }

    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final iconColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    return Row(
      children: [
        // Notifications
        CompositedTransformTarget(
          link: _notificationLayerLink,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: _notificationMenuKey,
                onPressed: _toggleNotificationMenu,
                icon: Icon(
                  _showNotificationMenu
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  color: _showNotificationMenu ? AppColors.primary : iconColor,
                  size: 24,
                ),
                splashRadius: 24,
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.unreadCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF121212)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          provider.unreadCount > 9
                              ? '9+'
                              : provider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // User Profile Dropdown
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _userMenuKey,
            onTap: _toggleUserMenu,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(32),
                  border: isDark ? null : Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF535353),
                        shape: BoxShape.circle,
                        image: userPicture != null && userPicture.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(userPicture),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: userPicture == null || userPicture.isEmpty
                          ? Center(
                              child: Text(
                                userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showUserMenu
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: textColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF282828) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final iconColor = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final hoverColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              _toggleUserMenu();
              widget.onNavigateTo(AppTabs.profile);
            },
            textColor: textColor,
            iconColor: iconColor,
            hoverColor: hoverColor,
          ),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            height: 1,
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            label: 'Log out',
            onTap: () {
              _toggleUserMenu();
              _showLogoutConfirmation();
            },
            textColor: textColor,
            iconColor: iconColor,
            hoverColor: hoverColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color iconColor,
    required Color hoverColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: textColor, fontSize: 14)),
              const Spacer(),
              if (label == 'Profile')
                Icon(
                  Icons.open_in_new_rounded,
                  color: iconColor.withOpacity(0.7),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF282828) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Log out?',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF282828) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSecondary;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 450),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<NotificationProvider>().markAllAsRead();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.notifications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                if (provider.notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 40,
                            color: subColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications',
                            style: TextStyle(color: subColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: provider.notifications.length > 5
                      ? 5
                      : provider.notifications.length,
                  itemBuilder: (context, index) {
                    final n = provider.notifications[index];
                    return InkWell(
                      onTap: () {
                        _toggleNotificationMenu();
                        showNotificationDetail(context, n);
                        // Also mark read as per user request
                        provider.markAllAsRead();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: !n.viewed
                            ? (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : AppColors.primary.withOpacity(0.05))
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n.imageUrl != null && n.imageUrl!.isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  image: DecorationImage(
                                    image: NetworkImage(n.imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.notifications_none,
                                  size: 20,
                                  color: subColor,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: !n.viewed
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.description,
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              _toggleNotificationMenu();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'See all notifications',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
