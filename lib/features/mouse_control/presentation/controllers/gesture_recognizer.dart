import 'dart:async';
import 'dart:ui';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/mouse_command.dart';

/// Tracks one active finger for the lifetime of a touch session.
class _PointerRecord {
  _PointerRecord({required this.start, required this.last});

  final Offset start;
  Offset last;
  bool moved = false;
}

enum _TwoFingerGesture { undetermined, scroll, pinch }

/// Turns raw multi-touch pointer events into [MouseCommand]s.
///
/// This is pure Dart (no Flutter widget dependencies beyond [Offset]) so it
/// can be unit-tested by simulating pointer down/move/up calls directly -
/// see `test/features/mouse_control/gesture_recognizer_test.dart`.
///
/// Supported gestures, all driven purely by *how many fingers* touch and
/// *how they move relative to each other* - never by where on the phone
/// screen they land, since the screen is a touchpad, not a mapped surface:
///  * 1 finger, quick tap                    -> left click (tap)
///  * 1 finger, two quick taps                -> double click
///  * 1 finger, held still past a threshold   -> left button down (hold);
///    moving afterwards drags; lifting sends left button up
///  * 2 fingers, quick tap together           -> right click
///  * 2 fingers, moving vertically together   -> scroll
///  * 2 fingers, moving apart/together        -> pinch-to-zoom
///  * 3 fingers, swipe left/right             -> back / forward
class GestureRecognizer {
  GestureRecognizer({
    required this.onCommand,
    required this.onClutchChanged,
    this.leftHandedMode = false,
  });

  /// Fired for every fully-resolved gesture, ready to be sent over the wire.
  final void Function(MouseCommand command) onCommand;

  /// Fired the instant the first finger touches down (`true`) and the
  /// instant the last finger lifts (`false`) - the Smart Clutch signal.
  final void Function(bool engaged) onClutchChanged;

  /// When true, swaps which tap maps to left vs. right click, mirroring the
  /// primary/secondary button swap convention of physical left-handed mice.
  /// Long-press-to-drag intentionally stays a single-finger gesture either
  /// way, since it's specified as "hold left click" regardless of handedness.
  bool leftHandedMode;

  final Map<int, _PointerRecord> _pointers = {};

  int _maxPointerCount = 0;
  bool _sessionResolved = false;
  bool _anyPointerMoved = false;
  DateTime? _sessionStartTime;

  Timer? _longPressTimer;
  bool _longPressActive = false;

  Timer? _pendingSingleTapTimer;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  double? _twoFingerBaseAvgY;
  double? _twoFingerBaseDistance;
  _TwoFingerGesture _twoFingerGesture = _TwoFingerGesture.undetermined;

  double? _threeFingerBaseAvgX;
  bool _threeFingerFired = false;

  static const double _scrollSpeedFactor = 0.6;
  static const double _pinchSpeedFactor = 0.01;

  // --- Public pointer API, called from the touchpad's Listener widget ------

  void handlePointerDown(int id, Offset position) {
    final wasEmpty = _pointers.isEmpty;
    _pointers[id] = _PointerRecord(start: position, last: position);

    if (wasEmpty) {
      _sessionStartTime = DateTime.now();
      _maxPointerCount = 1;
      _sessionResolved = false;
      _anyPointerMoved = false;
      onClutchChanged(true);
      _startLongPressTimer();
    } else {
      _maxPointerCount = _pointers.length > _maxPointerCount ? _pointers.length : _maxPointerCount;
      _cancelLongPressTimer();
      if (_longPressActive) {
        _endDrag();
      }
    }

    if (_pointers.length == 2) {
      _twoFingerBaseAvgY = _averageY();
      _twoFingerBaseDistance = _pointerDistance();
      _twoFingerGesture = _TwoFingerGesture.undetermined;
    }
    if (_pointers.length == 3) {
      _threeFingerBaseAvgX = _averageX();
      _threeFingerFired = false;
    }
  }

  void handlePointerMove(int id, Offset position) {
    final record = _pointers[id];
    if (record == null) return;
    record.last = position;

    if (!record.moved && (position - record.start).distance > AppConstants.tapMaxSlopPx) {
      record.moved = true;
      _anyPointerMoved = true;
      _cancelLongPressTimer();
    }

    if (_pointers.length == 2) {
      _handleTwoFingerMove();
    } else if (_pointers.length == 3) {
      _handleThreeFingerMove();
    }
  }

  void handlePointerUp(int id) {
    final record = _pointers.remove(id);
    if (record == null) return;

    if (_pointers.isEmpty) {
      _cancelLongPressTimer();
      if (_longPressActive) {
        _endDrag();
      } else if (!_sessionResolved) {
        _classifyTapSession(record.start);
      }
      onClutchChanged(false);
      _resetSessionState();
    } else if (_pointers.length == 2) {
      _twoFingerBaseAvgY = _averageY();
      _twoFingerBaseDistance = _pointerDistance();
      _twoFingerGesture = _TwoFingerGesture.undetermined;
    }
  }

  /// Same handling as [handlePointerUp] but never classifies a tap - used
  /// when the platform cancels a gesture (e.g. an incoming system gesture).
  void handlePointerCancel(int id) {
    final record = _pointers.remove(id);
    if (record == null) return;
    if (_pointers.isEmpty) {
      _cancelLongPressTimer();
      if (_longPressActive) _endDrag();
      onClutchChanged(false);
      _resetSessionState();
    }
  }

  void dispose() {
    _longPressTimer?.cancel();
    _pendingSingleTapTimer?.cancel();
  }

  // --- Two/three finger continuous gestures --------------------------------

  void _handleTwoFingerMove() {
    if (_twoFingerBaseAvgY == null || _twoFingerBaseDistance == null) return;
    final currentAvgY = _averageY();
    final currentDistance = _pointerDistance();
    final yDelta = currentAvgY - _twoFingerBaseAvgY!;
    final distanceDelta = currentDistance - _twoFingerBaseDistance!;

    if (_twoFingerGesture == _TwoFingerGesture.undetermined) {
      final pinchDominant = distanceDelta.abs() > AppConstants.pinchThresholdPx &&
          distanceDelta.abs() > yDelta.abs();
      final scrollDominant = yDelta.abs() > AppConstants.swipeThresholdPx;

      if (pinchDominant) {
        _twoFingerGesture = _TwoFingerGesture.pinch;
        _sessionResolved = true;
      } else if (scrollDominant) {
        _twoFingerGesture = _TwoFingerGesture.scroll;
        _sessionResolved = true;
      } else {
        return; // Not enough movement yet to tell scroll from pinch.
      }
    }

    if (_twoFingerGesture == _TwoFingerGesture.scroll) {
      onCommand(ScrollCommand(dy: yDelta * _scrollSpeedFactor));
      _twoFingerBaseAvgY = currentAvgY;
    } else if (_twoFingerGesture == _TwoFingerGesture.pinch) {
      onCommand(ZoomCommand(delta: distanceDelta * _pinchSpeedFactor));
      _twoFingerBaseDistance = currentDistance;
    }
  }

  void _handleThreeFingerMove() {
    if (_threeFingerBaseAvgX == null || _threeFingerFired) return;
    final currentAvgX = _averageX();
    final delta = currentAvgX - _threeFingerBaseAvgX!;
    if (delta.abs() > AppConstants.swipeThresholdPx * 2) {
      onCommand(delta < 0 ? const BackCommand() : const ForwardCommand());
      _threeFingerFired = true;
      _sessionResolved = true;
    }
  }

  // --- Long press / drag ----------------------------------------------------

  void _startLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(AppConstants.longPressDuration, () {
      if (_pointers.length != 1) return;
      final record = _pointers.values.first;
      if (record.moved) return;
      _longPressActive = true;
      _sessionResolved = true;
      onCommand(const LeftButtonDownCommand());
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _endDrag() {
    _longPressActive = false;
    onCommand(const LeftButtonUpCommand());
  }

  // --- Tap / double-tap -----------------------------------------------------

  void _classifyTapSession(Offset lastFingerPosition) {
    final start = _sessionStartTime;
    final elapsed = start == null ? Duration.zero : DateTime.now().difference(start);
    if (_anyPointerMoved || elapsed > AppConstants.tapMaxDuration) return;

    switch (_maxPointerCount) {
      case 1:
        _registerSingleFingerTap(lastFingerPosition);
        break;
      case 2:
        onCommand(leftHandedMode ? const LeftClickCommand() : const RightClickCommand());
        break;
      default:
        break; // 3+ finger taps aren't mapped to any action.
    }
  }

  void _registerSingleFingerTap(Offset position) {
    final now = DateTime.now();
    final isSecondTap = _lastTapTime != null &&
        now.difference(_lastTapTime!) <= AppConstants.doubleTapWindow &&
        _lastTapPosition != null &&
        (position - _lastTapPosition!).distance <= AppConstants.tapMaxSlopPx * 2;

    if (isSecondTap) {
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;
      _lastTapTime = null;
      _lastTapPosition = null;
      onCommand(const DoubleClickCommand());
      return;
    }

    _lastTapTime = now;
    _lastTapPosition = position;
    _pendingSingleTapTimer?.cancel();
    _pendingSingleTapTimer = Timer(AppConstants.doubleTapWindow, () {
      onCommand(leftHandedMode ? const RightClickCommand() : const LeftClickCommand());
      _lastTapTime = null;
      _lastTapPosition = null;
    });
  }

  // --- Helpers ----------------------------------------------------------------

  double _averageY() {
    var sum = 0.0;
    for (final p in _pointers.values) {
      sum += p.last.dy;
    }
    return sum / _pointers.length;
  }

  double _averageX() {
    var sum = 0.0;
    for (final p in _pointers.values) {
      sum += p.last.dx;
    }
    return sum / _pointers.length;
  }

  double _pointerDistance() {
    if (_pointers.length < 2) return 0;
    final points = _pointers.values.toList(growable: false);
    return (points[0].last - points[1].last).distance;
  }

  void _resetSessionState() {
    _maxPointerCount = 0;
    _sessionResolved = false;
    _anyPointerMoved = false;
    _sessionStartTime = null;
    _twoFingerBaseAvgY = null;
    _twoFingerBaseDistance = null;
    _twoFingerGesture = _TwoFingerGesture.undetermined;
    _threeFingerBaseAvgX = null;
    _threeFingerFired = false;
  }
}
