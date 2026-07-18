import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';

class _GestureHint {
  const _GestureHint(this.icon, this.gesture, this.action);
  final IconData icon;
  final String gesture;
  final String action;
}

const _hints = [
  _GestureHint(Icons.touch_app_rounded, 'Single tap', 'Left click'),
  _GestureHint(Icons.tap_and_play_rounded, 'Double tap', 'Double click'),
  _GestureHint(Icons.front_hand_rounded, 'Two-finger tap', 'Right click'),
  _GestureHint(Icons.timer_rounded, 'Long press', 'Hold left click'),
  _GestureHint(Icons.open_with_rounded, 'Long press + move', 'Drag'),
  _GestureHint(Icons.swipe_vertical_rounded, 'Two-finger vertical swipe', 'Scroll'),
  _GestureHint(Icons.swipe_left_rounded, 'Three-finger swipe left', 'Back'),
  _GestureHint(Icons.swipe_right_rounded, 'Three-finger swipe right', 'Forward'),
  _GestureHint(Icons.pinch_rounded, 'Pinch', 'Zoom'),
];

/// The full gesture legend, reachable from Mouse Mode's info button. Kept as
/// a separate widget (rather than inline in the page) so it's easy to reuse
/// from onboarding later without duplicating the list.
class GestureHintOverlay extends StatelessWidget {
  const GestureHintOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const GestureHintOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GlassContainer(
          borderRadius: 28,
          blurSigma: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestures', style: AppTextStyles.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Move the phone to steer the cursor. Touches are only for actions.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
              for (final hint in _hints)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.purple.withValues(alpha: 0.16),
                        ),
                        child: Icon(hint.icon, size: 18, color: AppColors.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(hint.gesture, style: AppTextStyles.body),
                      ),
                      Text(
                        hint.action,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
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
