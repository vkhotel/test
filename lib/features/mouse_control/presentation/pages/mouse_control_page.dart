import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_gradient_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../connection/domain/entities/connection_info.dart';
import '../../../connection/presentation/controllers/connection_notifier.dart';
import '../controllers/mouse_control_notifier.dart';
import '../widgets/clutch_indicator.dart';
import '../widgets/gesture_hint_overlay.dart';
import '../widgets/mouse_mode_stats_overlay.dart';
import '../widgets/touchpad_surface.dart';

/// The full-screen touchpad. Every finger touch is an *action*; cursor
/// motion comes entirely from the phone's own movement (see the motion
/// engine), which is why this page deliberately has no draggable cursor
/// visual tied to finger position - that would misrepresent how the
/// feature works.
class MouseControlPage extends ConsumerStatefulWidget {
  const MouseControlPage({super.key});

  @override
  ConsumerState<MouseControlPage> createState() => _MouseControlPageState();
}

class _MouseControlPageState extends ConsumerState<MouseControlPage> {
  String? _toastLabel;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    unawaited(WakelockPlus.enable());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mouseControlNotifierProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    ref.read(mouseControlNotifierProvider.notifier).stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _showToast(String label) {
    setState(() => _toastLabel = label);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _toastLabel = null);
    });
  }

  Widget _buildHeader(ConnectionInfo connectionInfo) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(child: MouseModeStatsOverlay(info: connectionInfo)),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ExitButton(),
                  _InfoButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClutchIndicator(MouseControlState mouseState) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: IgnorePointer(
            child: ClutchIndicator(
              isEngaged: mouseState.isClutchEngaged,
              isDragging: mouseState.isDragging,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestureToast() {
    return Align(
      alignment: const Alignment(0, -0.55),
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _toastLabel == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : GlassContainer(
                  key: ValueKey(_toastLabel),
                  borderRadius: 999,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Text(_toastLabel!, style: AppTextStyles.titleMedium),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MouseControlState>(mouseControlNotifierProvider, (previous, next) {
      if (next.lastGestureLabel != null && next.lastGestureLabel != previous?.lastGestureLabel) {
        _showToast(next.lastGestureLabel!);
      }
    });

    final mouseState = ref.watch(mouseControlNotifierProvider);
    final connectionInfo = ref.watch(connectionNotifierProvider);
    final notifier = ref.read(mouseControlNotifierProvider.notifier);

    final touchpad = Positioned.fill(
      child: TouchpadSurface(
        isClutchEngaged: mouseState.isClutchEngaged,
        isDragging: mouseState.isDragging,
        onPointerDown: notifier.handlePointerDown,
        onPointerMove: notifier.handlePointerMove,
        onPointerUp: notifier.handlePointerUp,
        onPointerCancel: notifier.handlePointerCancel,
      ),
    );

    final stack = Stack(
      children: [
        touchpad,
        _buildHeader(connectionInfo),
        _buildClutchIndicator(mouseState),
        _buildGestureToast(),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(child: stack),
    );
  }
}

class _ExitButton extends StatelessWidget {
  const _ExitButton();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 999,
      blurSigma: 16,
      padding: EdgeInsets.zero,
      child: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Exit Mouse Mode',
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 999,
      blurSigma: 16,
      padding: EdgeInsets.zero,
      child: IconButton(
        onPressed: () => GestureHintOverlay.show(context),
        icon: const Icon(Icons.info_outline_rounded),
        tooltip: 'Gesture guide',
      ),
    );
  }
}
