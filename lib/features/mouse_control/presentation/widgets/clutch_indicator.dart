import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';

/// Tells the user, in words, exactly what the Smart Clutch is doing right
/// now - "Active" while a finger is down and steering the cursor, or
/// "Lifted - reposition your hand" the instant every finger leaves the
/// glass, mirroring what happens when you lift a physical mouse off the
/// desk to recenter your hand.
class ClutchIndicator extends StatelessWidget {
  const ClutchIndicator({super.key, required this.isEngaged, required this.isDragging});

  final bool isEngaged;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final label = isDragging ? 'Dragging' : (isEngaged ? 'Active' : 'Lifted — reposition your hand');
    final color = isDragging ? AppColors.blue : (isEngaged ? AppColors.success : AppColors.textMuted);
    final icon = isDragging
        ? Icons.pan_tool_alt_rounded
        : (isEngaged ? Icons.gesture_rounded : Icons.pause_circle_outline_rounded);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: GlassContainer(
        key: ValueKey('$isEngaged-$isDragging'),
        borderRadius: 999,
        blurSigma: 16,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
