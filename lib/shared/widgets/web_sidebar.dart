import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/library_service.dart';

/// Spotify-style Web Sidebar
///
/// Collapsible left sidebar with Your Library, playlists, and artists.
class WebSidebar extends StatefulWidget {
  const WebSidebar({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onPlaylistSelected,
  });

  final int currentTabIndex;
  final ValueChanged<int> onTabSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Function(String id, String title)? onPlaylistSelected;

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  String _activeFilter = 'Playlists'; // Playlists, Artists
  final TextEditingController _searchController = TextEditingController();
  final bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch playlists on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LibraryService>().getPlaylists();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.isCollapsed) {
      return _buildCollapsedSidebar(isDark);
    }
    return _buildExpandedSidebar(isDark);
  }

  /// Collapsed sidebar - just icons
  Widget _buildCollapsedSidebar(bool isDark) {
    return Container(
      width: 72,
      color: isDark ? const Color(0xFF121212) : AppColors.lightSurface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              isDark
                  ? 'assets/images/branding_dark.png'
                  : 'assets/images/branding_light.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          // Library Icon (only one needed)
          IconButton(
            onPressed: widget.onToggleCollapse, // Expand when clicked
            icon: Icon(
              Icons.library_music_rounded,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
              size: 28,
            ),
            tooltip: 'Expand Library',
          ),

          const Spacer(),

          // Expand button
          IconButton(
            onPressed: widget.onToggleCollapse,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
            ),
            tooltip: 'Expand',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Expanded sidebar - full content
  Widget _buildExpandedSidebar(bool isDark) {
    return Container(
      width: 280,
      color: isDark ? const Color(0xFF121212) : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Logo in expanded sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Library header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.library_music,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Your Library',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _buildLibraryAction(
                          Icons.add_rounded,
                          'Create playlist',
                          isDark,
                          () {},
                        ),
                        const SizedBox(width: 8),
                        if (widget.onToggleCollapse != null)
                          _buildLibraryAction(
                            Icons.arrow_back_rounded,
                            'Collapse',
                            isDark,
                            widget.onToggleCollapse!,
                          ),
                      ],
                    ),
                  ),

                  // Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [_buildFilterPill('Playlists', isDark)],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Library content (Scrollable)
                  Expanded(
                    child: Consumer<LibraryService>(
                      builder: (context, library, child) {
                        return _buildLibraryContent(library);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final isActive = widget.currentTabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTabSelected(index),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? Colors.white : Colors.white54,
                size: 26,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryAction(
    IconData icon,
    String tooltip,
    bool isDark,
    VoidCallback onTap,
  ) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
        size: 20,
      ),
      splashRadius: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
    );
  }

  Widget _buildFilterPill(String label, bool isDark) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent(LibraryService library) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // if (_activeFilter == 'Playlists') {
    return _buildPlaylistsList(library, isDark);
    // } else {
    //   return _buildArtistsList(library);
    // }
  }

  Widget _buildPlaylistsList(LibraryService library, bool isDark) {
    if (library.isLoading && library.playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter by search
    final query = _searchController.text.toLowerCase();
    final playlists = library.playlists.where((p) {
      return p.name.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        // Always show Liked Songs first
        if (query.isEmpty || 'liked songs'.contains(query))
          _buildLibraryItem(
            isDark: isDark,
            imageUrl: null,
            title: 'Liked Songs',
            subtitle: 'Playlist • ${library.favorites.length} songs',
            icon: Icons.favorite_rounded,
            iconColor: Colors.purpleAccent,
            onTap: () {
              // Switch to Library tab to show Liked Songs
              widget.onTabSelected(2);
            },
          ),

        // User playlists
        ...playlists.map(
          (playlist) => _buildLibraryItem(
            isDark: isDark,
            imageUrl: playlist.coverUrl,
            title: playlist.name,
            subtitle: 'Playlist • ${playlist.trackCount} songs',
            onTap: () {
              // Switch to Library tab (same as Liked Songs)
              widget.onTabSelected(2);
            },
          ),
        ),

        // Placeholder if empty
        if (playlists.isEmpty && library.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Create your first playlist!',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildArtistsList(LibraryService library) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Follow artists to see them here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem({
    required bool isDark,
    String? imageUrl,
    required String title,
    required String subtitle,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: icon != null
                      ? LinearGradient(
                          colors: [
                            (iconColor ?? Colors.purple).withOpacity(0.8),
                            (iconColor ?? Colors.purple).withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: imageUrl == null && icon == null
                      ? Colors.grey[800]
                      : null,
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 22)
                    : (imageUrl == null || imageUrl.isEmpty
                          ? const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white54,
                              size: 22,
                            )
                          : null),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
