import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/connection_status.dart';

/// A small dot that pulses while working (discovering/connecting/
/// reconnecting), glows steady green when connected, and sits flat red on
/// error - the "animated connection indicator" called for in the spec.
class AnimatedConnectionIndicator extends StatefulWidget {
  const AnimatedConnectionIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  final ConnectionStatus status;
  final double size;

  @override
  State<AnimatedConnectionIndicator> createState() => _AnimatedConnectionIndicatorState();
}

class _AnimatedConnectionIndicatorState extends State<AnimatedConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.status) {
        ConnectionStatus.connected => AppColors.success,
        ConnectionStatus.connecting ||
        ConnectionStatus.discovering ||
        ConnectionStatus.reconnecting =>
          AppColors.warning,
        ConnectionStatus.error => AppColors.danger,
        ConnectionStatus.disconnected => AppColors.textMuted,
      };

  bool get _isPulsing => widget.status != ConnectionStatus.connected &&
      widget.status != ConnectionStatus.disconnected &&
      widget.status != ConnectionStatus.error;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _isPulsing ? _controller.value : (widget.status == ConnectionStatus.connected ? 0.6 : 0.0);
        return SizedBox(
          width: widget.size * 2.4,
          height: widget.size * 2.4,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * (1.6 + t * 0.8),
                  height: widget.size * (1.6 + t * 0.8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color.withValues(alpha: 0.18 + (widget.status == ConnectionStatus.connected ? 0.1 : t * 0.12)),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color,
                    boxShadow: [
                      BoxShadow(color: _color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
