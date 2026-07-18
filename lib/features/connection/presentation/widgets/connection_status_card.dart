import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/connection_info.dart';
import '../../domain/entities/connection_status.dart';
import 'animated_connection_indicator.dart';

/// The headline card on the Home screen: big Connected/Disconnected label,
/// the connection method (WiFi), and which host it's talking to.
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key, required this.info});

  final ConnectionInfo info;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          AnimatedConnectionIndicator(status: info.status),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.status.label, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(_subtitle, style: AppTextStyles.bodyMuted, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _MethodChip(method: info.connectionMethod, active: info.isConnected),
        ],
      ),
    );
  }

  String get _subtitle {
    if (info.isConnected && info.hostIp != null) {
      return 'Streaming to ${info.hostIp}:${info.hostPort}';
    }
    if (info.status == ConnectionStatus.discovering) {
      return 'Scanning your network for AeroTouch receivers…';
    }
    if (info.status == ConnectionStatus.reconnecting) {
      return 'Connection dropped - reconnecting automatically…';
    }
    if (info.status == ConnectionStatus.error) {
      return info.errorMessage ?? 'Could not reach the desktop receiver.';
    }
    return 'Tap Connect to find a desktop receiver on this network.';
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method, required this.active});

  final String method;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? AppColors.blue.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: active ? AppColors.blue.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_rounded, size: 14, color: active ? AppColors.info : AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            method,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.info : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
