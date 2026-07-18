import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// The shared full-screen backdrop: a static dark gradient base plus two
/// slowly drifting, softly blurred color orbs. Runs a single, cheap
/// [AnimationController] (no rebuilds outside `CustomPaint`) so it stays at
/// 60fps even while the touchpad above it is tracking motion.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.backdrop),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _OrbPainter(progress: _controller.value),
                  size: Size.infinite,
                );
              },
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * 3.14159265;

    final purpleCenter = Offset(
      size.width * (0.2 + 0.10 * _osc(t)),
      size.height * (0.18 + 0.06 * _osc(t + 1.4)),
    );
    final blueCenter = Offset(
      size.width * (0.82 + 0.08 * _osc(t + 2.1)),
      size.height * (0.78 + 0.08 * _osc(t + 0.6)),
    );

    final purplePaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.purple.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(center: purpleCenter, radius: size.width * 0.55));

    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.blue.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(Rect.fromCircle(center: blueCenter, radius: size.width * 0.5));

    canvas.drawCircle(purpleCenter, size.width * 0.55, purplePaint);
    canvas.drawCircle(blueCenter, size.width * 0.5, bluePaint);
  }

  double _osc(double t) => (t.remainder(2 * 3.14159265) - 3.14159265).abs() / 3.14159265 * 2 - 1;

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => oldDelegate.progress != progress;
}
