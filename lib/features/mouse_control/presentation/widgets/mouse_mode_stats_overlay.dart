import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../connection/domain/entities/connection_info.dart';

/// A compact, unobtrusive latency/FPS readout for while you're actively
/// using Mouse Mode - deliberately smaller and quieter than the Home
/// screen's full stats grid so it never distracts from the touchpad itself.
class MouseModeStatsOverlay extends StatelessWidget {
  const MouseModeStatsOverlay({super.key, required this.info});

  final ConnectionInfo info;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 999,
      blurSigma: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 14, color: AppColors.qualityColor(_latencyGoodness)),
          const SizedBox(width: 4),
          Text('${info.latencyMs}ms', style: AppTextStyles.caption),
          const SizedBox(width: 10),
          const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.purple),
          const SizedBox(width: 4),
          Text(info.fps > 0 ? '${info.fps.toStringAsFixed(0)} Hz' : '—', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  double get _latencyGoodness => (1 - (info.latencyMs - 20) / 100).clamp(0.0, 1.0).toDouble();
}
