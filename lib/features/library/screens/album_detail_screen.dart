import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/aura_cards.dart';

/// Album Detail Screen - Neon Horizon
/// 
/// Immersive detail view with rotating vinyl animation.
class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  
  const AlbumDetailScreen({
    super.key, 
    required this.albumId,
    // Accepting basic info to show immediately before loading full details
    this.coverUrl = 'https://picsum.photos/400', 
    this.title = 'Neon Nights', 
    this.artist = 'The Midnight',
  });

  final String coverUrl;
  final String title;
  final String artist;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _rotationController;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // Fade in sticky header background
    setState(() {
      _opacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: (isDark ? AppColors.darkBg : Colors.white).withOpacity(_opacity),
        elevation: 0,
        title: Opacity(
          opacity: _opacity,
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
             child: Container(
               color: isDark ? AppColors.darkBg : AppColors.lightBg,
             ),
          ),
          Positioned(
             top: 0,
             left: 0,
             right: 0,
             height: 500,
             child: Container(
               decoration: BoxDecoration(
                 image: DecorationImage(
                   image: CachedNetworkImageProvider(widget.coverUrl),
                   fit: BoxFit.cover,
                   colorFilter: ColorFilter.mode(
                     Colors.black.withOpacity(0.6), 
                     BlendMode.darken
                   ),
                 ),
               ),
               child: Container(
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [
                       Colors.transparent,
                       isDark ? AppColors.darkBg : AppColors.lightBg,
                     ],
                   ),
                 ),
               ),
             ),
          ),

          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                 child: Padding(
                   padding: EdgeInsets.only(
                     top: MediaQuery.of(context).padding.top + 60,
                     bottom: AppSpacing.xl,
                   ),
                   child: Column(
                     children: [
                       // Rotating Vinyl Hero
                       GestureDetector(
                         onTap: () {
                           if (_rotationController.isAnimating) {
                             _rotationController.stop();
                           } else {
                             _rotationController.repeat();
                           }
                         },
                         child: AnimatedBuilder(
                           animation: _rotationController,
                           builder: (context, child) {
                             return Transform.rotate(
                               angle: _rotationController.value * 2 * math.pi,
                               child: child,
                             );
                           },
                           child: Container(
                             width: 240,
                             height: 240,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               image: DecorationImage(
                                 image: CachedNetworkImageProvider(widget.coverUrl),
                                 fit: BoxFit.cover,
                               ),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.4),
                                   blurRadius: 30,
                                   spreadRadius: -5,
                                   offset: const Offset(0, 20),
                                 ),
                               ],
                               border: Border.all(
                                 color: Colors.white.withOpacity(0.1),
                                 width: 8,
                               ),
                             ),
                             child: Center(
                               child: Container(
                                 width: 20,
                                 height: 20,
                                 decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                 ),
                               ),
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(height: AppSpacing.xxl),
                       
                       // Album Info
                       Text(
                         widget.title,
                         style: theme.textTheme.displaySmall?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: AppSpacing.xs),
                       Text(
                         widget.artist,
                         style: theme.textTheme.titleMedium?.copyWith(
                           color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                         ),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: AppSpacing.lg),
                       
                       // Actions
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           // Play Button
                           Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              ),
                           ),
                           const SizedBox(width: AppSpacing.lg),
                           // Shuffle
                           IconButton(
                             onPressed: () {},
                             icon: const Icon(Icons.shuffle_rounded, size: 28),
                             color: isDark ? Colors.white : Colors.black,
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
              ),

              // Tracklist
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                       return Padding(
                         padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                         child: AuraTrackTile(
                           index: index + 1,
                           title: 'Track Title ${index + 1}',
                           subtitle: widget.artist,
                           duration: '3:45',
                           isPlaying: index == 2, // Mocking active state
                           onTap: () {},
                         ),
                       );
                    },
                    childCount: 12, // Mock track count
                  ),
                ),
              ),
              
               const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
