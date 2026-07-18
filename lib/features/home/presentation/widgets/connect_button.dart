import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../connection/domain/entities/connection_status.dart';
import '../../../connection/presentation/controllers/connection_notifier.dart';
import '../../../connection/presentation/widgets/discovered_hosts_sheet.dart';

/// The Home screen's large primary action: opens device discovery when
/// disconnected, or disconnects the active session when connected.
class ConnectButton extends ConsumerWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(connectionNotifierProvider);
    final isBusy = info.status == ConnectionStatus.connecting ||
        info.status == ConnectionStatus.discovering ||
        info.status == ConnectionStatus.reconnecting;

    if (info.isConnected) {
      return GradientButton(
        label: 'Disconnect',
        icon: Icons.link_off_rounded,
        gradient: AppGradients.primaryDeep,
        onPressed: () => ref.read(connectionNotifierProvider.notifier).disconnect(),
      );
    }

    return GradientButton(
      label: isBusy ? 'Connecting…' : 'Connect',
      icon: Icons.bolt_rounded,
      isLoading: isBusy,
      onPressed: () => DiscoveredHostsSheet.show(context),
    );
  }
}
