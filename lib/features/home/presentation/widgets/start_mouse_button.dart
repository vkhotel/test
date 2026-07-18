import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../connection/presentation/controllers/connection_notifier.dart';
import '../../../mouse_control/presentation/pages/mouse_control_page.dart';

/// Launches the full-screen touchpad. Disabled (visually + functionally)
/// until AeroTouch has an active connection - there would be nowhere to
/// send commands otherwise.
class StartMouseButton extends ConsumerWidget {
  const StartMouseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectionNotifierProvider).isConnected;

    return GradientButton(
      label: 'Start Mouse Mode',
      icon: Icons.mouse_rounded,
      enabled: isConnected,
      onPressed: isConnected
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MouseControlPage()),
              )
          : null,
    );
  }
}
