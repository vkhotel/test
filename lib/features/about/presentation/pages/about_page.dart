import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_label.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: AppGradients.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: -6,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mouse_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(AppConstants.appName, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text('Version $_version', style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const SectionLabel('What is AeroTouch?'),
          const SizedBox(height: 10),
          GlassCard(
            child: Text(
              'AeroTouch turns your Android phone into a high-precision '
              'wireless motion mouse for Windows, macOS, and Linux. Move '
              'the phone to steer the cursor with real IMU sensor fusion, '
              'and use touch gestures purely for clicks, drags, scrolling, '
              'and navigation - just like lifting and repositioning a '
              'physical mouse.',
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('How It Works'),
          const SizedBox(height: 10),
          const _InfoTile(
            icon: Icons.sensors_rounded,
            title: 'Motion Engine',
            body: 'Reads the gyroscope and accelerometer at 100Hz and fuses them '
                'with a complementary filter, so the cursor stays smooth and '
                'never drifts while the phone sits still.',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.pan_tool_alt_rounded,
            title: 'Smart Clutch',
            body: 'Lift your finger and the cursor freezes instantly, so you can '
                'reposition your hand - exactly like lifting a physical mouse '
                'off the desk. Touch back down and it resumes right where it '
                'left off.',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.wifi_tethering_rounded,
            title: 'Encrypted Wi-Fi Link',
            body: 'Streams over a local WebSocket connection with a heartbeat '
                'every 2 seconds, automatic reconnect, and live latency '
                'reporting - all on your own network, nothing leaves your LAN.',
          ),
          const SizedBox(height: 24),
          const SectionLabel('Credits'),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Built with Flutter & Riverpod', style: AppTextStyles.body),
                const SizedBox(height: 6),
                Text(
                  'Clean Architecture across dedicated feature modules for '
                  'connection, motion, settings, and mouse control.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 20, color: AppColors.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.bodyMuted.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
