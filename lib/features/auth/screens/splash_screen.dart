import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Aura Splash Screen
/// 
/// Premium animated entry screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set system UI to immersive for splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loop the pulse
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final isDark = theme.brightness == Brightness.dark;
     final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

     return Scaffold(
       backgroundColor: bgColor,
       body: Stack(
         alignment: Alignment.center,
         children: [
           // Ambient Glow (subtle)
           Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: RadialGradient(
                   center: Alignment.center,
                   radius: 1.5,
                   colors: [
                     (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                     Colors.transparent,
                   ],
                 ),
               ),
             ),
           ),

           // Logo Layout
           Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               // Animated Logo Container
               AnimatedBuilder(
                 animation: _controller,
                 builder: (context, child) {
                   return Transform.scale(
                     scale: _scaleAnimation.value,
                     child: child,
                   );
                 },
                 child: Container(
                   width: 160,
                   height: 160,
                   decoration: BoxDecoration(
                     color: isDark ? const Color(0xFF1a1a1c) : Colors.white,
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.2),
                         blurRadius: 30,
                         offset: const Offset(0, 10),
                       ),
                       // Inner glow for depth
                       BoxShadow(
                         color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                         blurRadius: 10,
                         spreadRadius: -2,
                       )
                     ],
                     border: Border.all(
                       color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                       width: 1,
                     ),
                   ),
                   child: Stack(
                     alignment: Alignment.center,
                     children: [
                       // Rotating Accent Ring (Mocked as static for now or simple rotation if needed)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        // Inner Core
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white, // Core needs to be bright
                            shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.white30,
                                 blurRadius: 20,
                                 spreadRadius: 2,
                               ),
                             ],
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                     ],
                   ),
                 ),
               ),

               const SizedBox(height: AppSpacing.xxl),

               // Typography
               Text(
                 'AURA',
                 style: theme.textTheme.displayMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   letterSpacing: 12.0, // Wide tracking
                   color: isDark ? Colors.white : AppColors.lightTextPrimary,
                 ),
               ),
               
               const SizedBox(height: AppSpacing.md),
               
               // Fade-in Subtext
               FadeTransition(
                 opacity: _fadeAnimation,
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Container(height: 1, width: 24, color: isDark ? Colors.white24 : Colors.black12),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                       child: Text(
                         'SOUND STUDIO',
                         style: theme.textTheme.labelSmall?.copyWith(
                           letterSpacing: 4.0,
                           color: isDark ? Colors.white38 : Colors.black38,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     Container(height: 1, width: 24, color: isDark ? Colors.white24 : Colors.black12),
                   ],
                 ),
               ),
             ],
           ),

           // Bottom Breathing Indicator
           Positioned(
             bottom: 60,
             child: AnimatedBuilder(
               animation: _controller,
               builder: (context, child) {
                 return Opacity(
                   opacity: (_scaleAnimation.value - 0.95) * 10, // Approximate breathing opacity
                   child: Container(
                     width: 6,
                     height: 6,
                     decoration: const BoxDecoration(
                       color: AppColors.primary,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.primary,
                           blurRadius: 10,
                           spreadRadius: 2,
                         )
                       ],
                     ),
                   ),
                 );
               },
             ),
           ),
         ],
       ),
     );
  }
}
