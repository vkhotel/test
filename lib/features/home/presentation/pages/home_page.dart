import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_label.dart';
import '../../../connection/presentation/controllers/connection_notifier.dart';
import '../../../connection/presentation/widgets/connection_status_card.dart';
import '../../../connection/presentation/widgets/device_stats_grid.dart';
import '../widgets/app_header.dart';
import '../widgets/connect_button.dart';
import '../widgets/start_mouse_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionInfo = ref.watch(connectionNotifierProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
        children: [
          const AppHeader(),
          const SizedBox(height: 32),
          const SectionLabel('Device Status'),
          const SizedBox(height: 10),
          ConnectionStatusCard(info: connectionInfo),
          const SizedBox(height: 14),
          DeviceStatsGrid(info: connectionInfo),
          const SizedBox(height: 32),
          const ConnectButton(),
          const SizedBox(height: 14),
          const StartMouseButton(),
        ],
      ),
    );
  }
}
