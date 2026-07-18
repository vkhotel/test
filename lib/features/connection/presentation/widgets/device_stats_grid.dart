import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../domain/entities/connection_info.dart';

/// The Battery / Latency / FPS / Device IP grid shown under the connection
/// status card on Home.
class DeviceStatsGrid extends StatelessWidget {
  const DeviceStatsGrid({super.key, required this.info});

  final ConnectionInfo info;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        StatTile(
          icon: Icons.language_rounded,
          label: 'DEVICE IP',
          value: info.localIp ?? '—',
          accentColor: AppColors.info,
        ),
        StatTile(
          icon: _batteryIcon,
          label: 'BATTERY',
          value: info.batteryLevel != null ? '${info.batteryLevel}%' : '—',
          accentColor: _batteryColor,
        ),
        StatTile(
          icon: Icons.speed_rounded,
          label: 'LATENCY',
          value: info.isConnected ? '${info.latencyMs} ms' : '—',
          accentColor: _latencyColor,
        ),
        StatTile(
          icon: Icons.graphic_eq_rounded,
          label: 'FPS',
          value: info.isConnected && info.fps > 0 ? info.fps.toStringAsFixed(0) : '—',
          accentColor: AppColors.purple,
        ),
      ],
    );
  }

  IconData get _batteryIcon {
    final level = info.batteryLevel;
    if (level == null) return Icons.battery_unknown_rounded;
    if (level >= 90) return Icons.battery_full_rounded;
    if (level >= 60) return Icons.battery_5_bar_rounded;
    if (level >= 40) return Icons.battery_3_bar_rounded;
    if (level >= 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  Color get _batteryColor {
    final level = info.batteryLevel;
    if (level == null) return AppColors.textMuted;
    return AppColors.qualityColor(level / 100);
  }

  Color get _latencyColor {
    if (!info.isConnected) return AppColors.textMuted;
    // <= 20ms great, >= 120ms poor.
    final normalized = (1 - (info.latencyMs - 20) / 100).clamp(0.0, 1.0).toDouble();
    return AppColors.qualityColor(normalized);
  }
}
