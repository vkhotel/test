import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';

/// The large, primary call-to-action button ("Connect", "Start Mouse Mode").
///
/// Animates a subtle press-scale and glow so it never feels like a flat
/// stock Material button, while still being a real [Material]/[InkWell]
/// underneath for correct ripple + accessibility behavior.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.gradient = AppGradients.primary,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final Gradient gradient;
  final double height;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.enabled && widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) => Transform.scale(scale: scale.value, child: child),
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => _controller.forward() : null,
        onTapUp: _isEnabled ? (_) => _controller.reverse() : null,
        onTapCancel: _isEnabled ? () => _controller.reverse() : null,
        child: Opacity(
          opacity: _isEnabled ? 1.0 : 0.45,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              gradient: widget.gradient,
              boxShadow: _isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: -6,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.height / 2),
                onTap: _isEnabled ? widget.onPressed : null,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: AppTextStyles.button.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
