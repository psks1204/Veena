import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Birthday Celebration Overlay ("Bomb")
///
/// A full-screen overlay with custom particle confetti animation and a
/// stylish "Happy Birthday" message card.
class BirthdayCelebrationOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final String userName;

  const BirthdayCelebrationOverlay({
    super.key,
    required this.onDismiss,
    required this.userName,
  });

  @override
  State<BirthdayCelebrationOverlay> createState() =>
      _BirthdayCelebrationOverlayState();
}

class _BirthdayCelebrationOverlayState extends State<BirthdayCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Loop the animation

    // Generate initial particles
    for (int i = 0; i < 100; i++) {
      _particles.add(_generateParticle(true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _ConfettiParticle _generateParticle(bool randomY) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.yellow,
      Colors.cyan,
    ];
    return _ConfettiParticle(
      color: colors[_random.nextInt(colors.length)],
      x: _random.nextDouble(),
      y: randomY
          ? _random.nextDouble()
          : -0.1, // Start above screen if not initial
      size: _random.nextDouble() * 10 + 5,
      speed: _random.nextDouble() * 0.5 + 0.2, // Random fall speed
      angle: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Semi-transparent background
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(color: Colors.black.withOpacity(0.8)),
        ),

        // 2. Confetti Animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                particles: _particles,
                random: _random,
                onParticleRespawn: () => _generateParticle(false),
              ),
            );
          },
        ),

        // 3. Birthday Card
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  const Icon(
                    Icons.cake_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Happy Birthday!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily:
                          'Pacifico', // Fallback to default if not available
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    widget.userName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    'Wishing you a day filled with joy, music, and wonderful moments.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Thank You! 🎉',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  Color color;
  double x;
  double y;
  double size;
  double speed;
  double angle; // Rotation angle
  double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Random random;
  final _ConfettiParticle Function() onParticleRespawn;

  _ConfettiPainter({
    required this.particles,
    required this.random,
    required this.onParticleRespawn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Update position
      p.y += p.speed * 0.01; // Move down
      p.angle += p.rotationSpeed; // Rotate

      // Respawn if off screen
      if (p.y > 1.0) {
        particles[i] = onParticleRespawn();
      }

      // Draw
      paint.color = p.color;

      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for animation
}
