import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/services/auth_service.dart';

/// Spotify-style Web Header Bar
/// 
/// Top header with navigation arrows, search bar, and user profile dropdown.
class WebHeader extends StatefulWidget {
  const WebHeader({
    super.key,
    required this.onSearch,
    required this.onNavigateTo,
  });

  final ValueChanged<String> onSearch;
  final ValueChanged<int> onNavigateTo;

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _showUserMenu = false;
  final GlobalKey _userMenuKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleUserMenu() {
    if (_showUserMenu) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _showUserMenu = false);
    } else {
      _showUserMenu = true;
      _overlayEntry = _createUserMenuOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {});
    }
  }

  OverlayEntry _createUserMenuOverlay() {
    final RenderBox renderBox = _userMenuKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleUserMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu
          Positioned(
            right: 16,
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: _buildUserMenu(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenu() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.account_circle_outlined,
            label: 'Account',
            onTap: () {
              _toggleUserMenu();
              // Account navigation
            },
          ),
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              _toggleUserMenu();
              widget.onNavigateTo(3); // Profile tab
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              _toggleUserMenu();
              // Settings navigation
            },
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            label: 'Log out',
            onTap: () {
              _toggleUserMenu();
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (label == 'Profile')
                Icon(Icons.open_in_new_rounded, color: Colors.white.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF121212),
      child: Row(
        children: [
          // Home Button (Corrected)
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => widget.onNavigateTo(0), // Go to Home
              icon: const Icon(Icons.home_filled, color: Colors.white, size: 22),
              splashRadius: 20,
              tooltip: 'Home',
            ),
          ),

          // Navigation arrows
          _buildNavigationArrows(),
          
          const SizedBox(width: 16),
          
          // Search bar
          Expanded(
            child: Center(
              child: _buildSearchBar(),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Right side actions
          _buildRightActions(),
        ],
      ),
    );
  }

  Widget _buildNavigationArrows() {
    return Row(
      children: [
        IconButton(
          onPressed: () {}, // TODO: Implement back
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 32),
          splashRadius: 24,
        ),
        IconButton(
          onPressed: () {}, // TODO: Implement forward
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 32),
          splashRadius: 24,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 400,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(24),
        border: _isSearchFocused ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'What do you want to play?',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(
            Icons.search,
            color: _isSearchFocused ? Colors.white : Colors.white54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: widget.onSearch,
      ),
    );
  }

  Widget _buildRightActions() {
    return Row(
      children: [
        // Notifications
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
          splashRadius: 20,
        ),
        const SizedBox(width: 16),
        
        // User Profile Dropdown
        GestureDetector(
          key: _userMenuKey,
          onTap: _toggleUserMenu,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF535353),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        context.read<AuthService>().userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.read<AuthService>().userName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _showUserMenu ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
