import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/settings_notifier.dart';
import '../widgets/glass_slider_tile.dart';
import '../widgets/glass_switch_tile.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Text('Settings', style: AppTextStyles.heroTitle.copyWith(fontSize: 32)),
          const SizedBox(height: 4),
          Text('Fine-tune how AeroTouch feels in your hand.', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 28),
          SettingsSection(
            title: 'Motion Engine',
            children: [
              GlassSliderTile(
                label: 'Sensitivity',
                description: 'Overall pointer speed for a given hand movement.',
                value: settings.sensitivity,
                min: 0.1,
                max: 3.0,
                onChanged: notifier.setSensitivity,
                valueLabel: (v) => '${v.toStringAsFixed(1)}x',
              ),
              GlassSliderTile(
                label: 'Dead Zone',
                description: 'Ignores tiny hand tremor before the cursor starts moving.',
                value: settings.deadZone,
                min: 0.0,
                max: 1.0,
                onChanged: notifier.setDeadZone,
                valueLabel: (v) => '${(v * 100).round()}%',
              ),
              GlassSliderTile(
                label: 'Pointer Acceleration',
                description: 'Higher values make fast flicks travel further while staying precise at low speed.',
                value: settings.acceleration,
                min: 1.0,
                max: 3.0,
                onChanged: notifier.setAcceleration,
                valueLabel: (v) => '${v.toStringAsFixed(1)}x',
              ),
              GlassSliderTile(
                label: 'Pointer Smoothing',
                description: 'Removes jitter. Higher values feel silkier but add a touch of latency.',
                value: settings.smoothing,
                min: 0.0,
                max: 0.95,
                onChanged: notifier.setSmoothing,
                valueLabel: (v) => '${(v * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Orientation & Grip',
            children: [
              GlassSwitchTile(
                icon: Icons.swap_horiz_rounded,
                label: 'Invert X Axis',
                description: 'Flip left/right motion.',
                value: settings.invertX,
                onChanged: notifier.setInvertX,
              ),
              GlassSwitchTile(
                icon: Icons.swap_vert_rounded,
                label: 'Invert Y Axis',
                description: 'Flip up/down motion.',
                value: settings.invertY,
                onChanged: notifier.setInvertY,
              ),
              GlassSwitchTile(
                icon: Icons.back_hand_rounded,
                label: 'Left-Handed Mode',
                description: 'Mirrors the touchpad action layout for left-hand use.',
                value: settings.leftHandedMode,
                onChanged: notifier.setLeftHandedMode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Appearance',
            children: [
              GlassSwitchTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                description: 'True black (AMOLED) canvas. Turn off for a slightly lifted twilight tone.',
                value: settings.amoledDarkMode,
                onChanged: notifier.setAmoledDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Connection',
            children: [
              GlassSwitchTile(
                icon: Icons.sync_rounded,
                label: 'Reconnect Automatically',
                description: 'Re-establish the link with exponential backoff if it drops mid-session.',
                value: settings.autoReconnect,
                onChanged: notifier.setAutoReconnect,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: () => _confirmReset(context, notifier),
              icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.textMuted),
              label: Text(
                'Reset to defaults',
                style: AppTextStyles.bodyMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, SettingsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset settings?'),
        content: const Text('This restores every slider and toggle to its default value.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.reset();
    }
  }
}
