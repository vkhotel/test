import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

/// The actual touch-capture surface. Every finger event on the whole screen
/// routes through here via [Listener], which is why this widget has no
/// `onTap`/`GestureDetector` of its own - all interpretation happens in
/// `GestureRecognizer` so multiple simultaneous fingers can be tracked.
class TouchpadSurface extends StatelessWidget {
  const TouchpadSurface({
    super.key,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.isClutchEngaged,
    required this.isDragging,
  });

  final void Function(int id, Offset position) onPointerDown;
  final void Function(int id, Offset position) onPointerMove;
  final void Function(int id) onPointerUp;
  final void Function(int id) onPointerCancel;
  final bool isClutchEngaged;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => onPointerDown(e.pointer, e.localPosition),
      onPointerMove: (e) => onPointerMove(e.pointer, e.localPosition),
      onPointerUp: (e) => onPointerUp(e.pointer),
      onPointerCancel: (e) => onPointerCancel(e.pointer),
      child: SizedBox.expand(
        child: Center(
          child: _CursorGlyph(isClutchEngaged: isClutchEngaged, isDragging: isDragging),
        ),
      ),
    );
  }
}

/// A soft, breathing glow that brightens while the Smart Clutch is engaged
/// (actively steering the remote cursor) and dims to a static "lifted mouse"
/// look the instant every finger leaves the glass - the core visual promise
/// of the Smart Clutch feature.
class _CursorGlyph extends StatefulWidget {
  const _CursorGlyph({required this.isClutchEngaged, required this.isDragging});

  final bool isClutchEngaged;
  final bool isDragging;

  @override
  State<_CursorGlyph> createState() => _CursorGlyphState();
}

class _CursorGlyphState extends State<_CursorGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final breathe = widget.isClutchEngaged ? _controller.value : 0.0;
        final baseSize = widget.isDragging ? 132.0 : 108.0;
        final size = baseSize + breathe * 14;
        final opacity = widget.isClutchEngaged ? 0.9 : 0.35;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (widget.isDragging ? AppColors.blue : AppColors.purple).withValues(alpha: opacity * 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: widget.isClutchEngaged ? 20 : 14,
              height: widget.isClutchEngaged ? 20 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: widget.isClutchEngaged ? 0.6 : 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
