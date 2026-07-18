import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/motion/motion_engine.dart';
import '../../../../core/motion/motion_models.dart';
import '../../../connection/presentation/providers/connection_providers.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/controllers/settings_notifier.dart';
import '../../domain/entities/mouse_command.dart';
import '../providers/mouse_control_providers.dart';
import 'gesture_recognizer.dart';

/// Everything the Mouse Mode UI needs to render: whether the session is
/// active, whether the Smart Clutch currently has control, and a short
/// human-readable label for the most recent gesture (for a small on-screen
/// toast).
class MouseControlState {
  const MouseControlState({
    this.isActive = false,
    this.isClutchEngaged = false,
    this.isDragging = false,
    this.lastGestureLabel,
  });

  final bool isActive;
  final bool isClutchEngaged;
  final bool isDragging;
  final String? lastGestureLabel;

  MouseControlState copyWith({
    bool? isActive,
    bool? isClutchEngaged,
    bool? isDragging,
    String? lastGestureLabel,
  }) {
    return MouseControlState(
      isActive: isActive ?? this.isActive,
      isClutchEngaged: isClutchEngaged ?? this.isClutchEngaged,
      isDragging: isDragging ?? this.isDragging,
      lastGestureLabel: lastGestureLabel ?? this.lastGestureLabel,
    );
  }
}

/// Wires the [MotionEngine] (raw sensors -> cursor deltas) and
/// [GestureRecognizer] (raw touches -> click/scroll/nav commands) together,
/// keeps both in sync with live [AppSettings] changes, and forwards every
/// resulting [MouseCommand] to the desktop over the connection feature.
class MouseControlNotifier extends Notifier<MouseControlState> {
  late final MotionEngine _motionEngine;
  late final GestureRecognizer _gestureRecognizer;
  StreamSubscription<MotionDelta>? _motionSub;
  StreamSubscription<double>? _fpsSub;

  @override
  MouseControlState build() {
    _motionEngine = MotionEngine();
    _gestureRecognizer = GestureRecognizer(
      onCommand: _handleGestureCommand,
      onClutchChanged: _handleClutchChanged,
      leftHandedMode: ref.read(settingsNotifierProvider).leftHandedMode,
    );

    // Keep tuning + handedness in sync with Settings for as long as this
    // provider is alive (the whole app lifetime - see the provider below).
    ref.listen<AppSettings>(settingsNotifierProvider, (previous, next) {
      _motionEngine.updateConfig(_motionConfigFrom(next));
      _gestureRecognizer.leftHandedMode = next.leftHandedMode;
    }, fireImmediately: true);

    ref.onDispose(() {
      _motionSub?.cancel();
      _fpsSub?.cancel();
      _motionEngine.dispose();
      _gestureRecognizer.dispose();
    });

    return const MouseControlState();
  }

  MotionConfig _motionConfigFrom(AppSettings settings) => MotionConfig(
        sensitivity: settings.sensitivity,
        deadZone: settings.deadZone,
        acceleration: settings.acceleration,
        smoothing: settings.smoothing,
        invertX: settings.invertX,
        invertY: settings.invertY,
      );

  /// Begins reading sensors and streaming motion. Call when entering the
  /// full-screen Mouse Mode page.
  void start() {
    if (state.isActive) return;
    _motionEngine.start();
    _motionSub = _motionEngine.deltaStream.listen((delta) {
      _send(MotionCommand(dx: delta.dx, dy: delta.dy));
    });
    _fpsSub = _motionEngine.fpsStream.listen((fps) {
      ref.read(connectionRepositoryProvider).reportFps(fps);
    });
    state = state.copyWith(isActive: true);
  }

  /// Stops sensors and clears any in-flight drag. Call when leaving Mouse
  /// Mode so the phone stops burning battery on 100Hz sensor reads.
  void stop() {
    unawaited(_motionSub?.cancel());
    unawaited(_fpsSub?.cancel());
    _motionEngine.stop();
    ref.read(connectionRepositoryProvider).reportFps(0);
    state = const MouseControlState();
  }

  void handlePointerDown(int id, Offset position) =>
      _gestureRecognizer.handlePointerDown(id, position);

  void handlePointerMove(int id, Offset position) =>
      _gestureRecognizer.handlePointerMove(id, position);

  void handlePointerUp(int id) => _gestureRecognizer.handlePointerUp(id);

  void handlePointerCancel(int id) => _gestureRecognizer.handlePointerCancel(id);

  void _handleClutchChanged(bool engaged) {
    if (engaged) {
      _motionEngine.engageClutch();
    } else {
      _motionEngine.disengageClutch();
    }
    state = state.copyWith(isClutchEngaged: engaged);
    ref.read(hapticsServiceProvider).clutchEngaged();
  }

  void _handleGestureCommand(MouseCommand command) {
    _send(command);
    _fireHaptic(command);

    if (command is LeftButtonDownCommand) {
      state = state.copyWith(isDragging: true, lastGestureLabel: 'Hold');
    } else if (command is LeftButtonUpCommand) {
      state = state.copyWith(isDragging: false, lastGestureLabel: 'Release');
    } else {
      state = state.copyWith(lastGestureLabel: _labelFor(command));
    }
  }

  void _send(MouseCommand command) {
    unawaited(ref.read(sendMouseCommandUseCaseProvider).call(command));
  }

  void _fireHaptic(MouseCommand command) {
    final haptics = ref.read(hapticsServiceProvider);
    switch (command) {
      case LeftClickCommand():
        haptics.leftClick();
        break;
      case RightClickCommand():
        haptics.rightClick();
        break;
      case DoubleClickCommand():
        haptics.doubleClick();
        break;
      case LeftButtonDownCommand():
        haptics.dragStart();
        break;
      case LeftButtonUpCommand():
        haptics.dragEnd();
        break;
      case BackCommand():
      case ForwardCommand():
        haptics.navigation();
        break;
      case ScrollCommand():
      case ZoomCommand():
      case MotionCommand():
        break;
    }
  }

  String _labelFor(MouseCommand command) => switch (command) {
        LeftClickCommand() => 'Left Click',
        DoubleClickCommand() => 'Double Click',
        RightClickCommand() => 'Right Click',
        LeftButtonDownCommand() => 'Hold',
        LeftButtonUpCommand() => 'Release',
        ScrollCommand() => 'Scroll',
        BackCommand() => 'Back',
        ForwardCommand() => 'Forward',
        ZoomCommand() => 'Zoom',
        MotionCommand() => 'Move',
      };
}

final mouseControlNotifierProvider = NotifierProvider<MouseControlNotifier, MouseControlState>(
  MouseControlNotifier.new,
);
