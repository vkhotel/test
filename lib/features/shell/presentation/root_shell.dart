import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/animated_gradient_background.dart';
import '../../about/presentation/pages/about_page.dart';
import '../../connection/presentation/providers/connection_providers.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../settings/domain/entities/app_settings.dart';
import '../../settings/presentation/controllers/settings_notifier.dart';
import '../../settings/presentation/pages/settings_page.dart';
import 'widgets/glass_bottom_nav.dart';

/// The app's composition root for cross-feature wiring that shouldn't live
/// inside any single feature: it hosts the three tabs and mirrors the
/// "Reconnect automatically" Settings toggle onto the connection repository,
/// keeping the Settings and Connection features themselves decoupled from
/// one another.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  static const _pages = <Widget>[HomePage(), SettingsPage(), AboutPage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final autoReconnect = ref.read(settingsNotifierProvider).autoReconnect;
      ref.read(connectionRepositoryProvider).setAutoReconnect(autoReconnect);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettings>(settingsNotifierProvider, (previous, next) {
      if (previous?.autoReconnect != next.autoReconnect) {
        ref.read(connectionRepositoryProvider).setAutoReconnect(next.autoReconnect);
      }
    });

    return Scaffold(
      body: AnimatedGradientBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _pages[_index],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GlassBottomNav(
                currentIndex: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
