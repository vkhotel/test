/// Every message AeroTouch can send to the desktop receiver, and how it
/// serializes to JSON over the WebSocket. See `tools/server/aerotouch_server.py`
/// for a reference implementation of the receiving end.
sealed class MouseCommand {
  const MouseCommand();

  Map<String, dynamic> toJson();
}

/// `{"type":"motion","dx":3.2,"dy":-1.4}`
class MotionCommand extends MouseCommand {
  const MotionCommand({required this.dx, required this.dy});

  final double dx;
  final double dy;

  @override
  Map<String, dynamic> toJson() => {'type': 'motion', 'dx': dx, 'dy': dy};
}

/// `{"type":"leftClick"}` - single tap.
class LeftClickCommand extends MouseCommand {
  const LeftClickCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'leftClick'};
}

/// `{"type":"doubleClick"}` - double tap.
class DoubleClickCommand extends MouseCommand {
  const DoubleClickCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'doubleClick'};
}

/// `{"type":"rightClick"}` - two-finger tap.
class RightClickCommand extends MouseCommand {
  const RightClickCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'rightClick'};
}

/// `{"type":"leftButtonDown"}` - long press start (hold left click for drag).
class LeftButtonDownCommand extends MouseCommand {
  const LeftButtonDownCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'leftButtonDown'};
}

/// `{"type":"leftButtonUp"}` - drag end / long press release.
class LeftButtonUpCommand extends MouseCommand {
  const LeftButtonUpCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'leftButtonUp'};
}

/// `{"type":"scroll","dy":-12.0,"dx":0.0}` - two-finger vertical swipe.
class ScrollCommand extends MouseCommand {
  const ScrollCommand({required this.dy, this.dx = 0});

  final double dy;
  final double dx;

  @override
  Map<String, dynamic> toJson() => {'type': 'scroll', 'dy': dy, 'dx': dx};
}

/// `{"type":"back"}` - three-finger swipe left.
class BackCommand extends MouseCommand {
  const BackCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'back'};
}

/// `{"type":"forward"}` - three-finger swipe right.
class ForwardCommand extends MouseCommand {
  const ForwardCommand();

  @override
  Map<String, dynamic> toJson() => {'type': 'forward'};
}

/// `{"type":"zoom","delta":0.08}` - pinch gesture. Positive = spreading
/// apart (zoom in), negative = pinching together (zoom out). The reference
/// desktop receiver maps this to a Ctrl+Scroll, which is the de-facto zoom
/// shortcut across browsers, editors, and image viewers - architected here
/// so a future release can add richer zoom targets without touching the
/// wire protocol.
class ZoomCommand extends MouseCommand {
  const ZoomCommand({required this.delta});

  final double delta;

  @override
  Map<String, dynamic> toJson() => {'type': 'zoom', 'delta': delta};
}
