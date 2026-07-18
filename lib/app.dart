import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/settings_notifier.dart';
import 'features/shell/presentation/root_shell.dart';

/// The app root. Deliberately tiny: theme selection based on the persisted
/// "Dark Mode" (AMOLED vs. twilight) preference, then hand off to
/// [RootShell] for everything else.
class AeroTouchApp extends ConsumerWidget {
  const AeroTouchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amoled = ref.watch(settingsNotifierProvider.select((s) => s.amoledDarkMode));

    return MaterialApp(
      title: 'AeroTouch',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.build(amoled: amoled),
      theme: AppTheme.build(amoled: amoled),
      home: const RootShell(),
    );
  }
}
