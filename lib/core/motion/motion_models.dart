/// One computed cursor-movement sample, ready to be sent to the desktop.
class MotionDelta {
  const MotionDelta({required this.dx, required this.dy});

  final double dx;
  final double dy;

  @override
  String toString() => 'MotionDelta(dx: ${dx.toStringAsFixed(3)}, dy: ${dy.toStringAsFixed(3)})';
}

/// Tunable parameters for [MotionEngine], sourced from [AppSettings] but
/// kept as its own lightweight type so `core/` never has to depend on a
/// feature package (see `features/mouse_control` for the mapping).
class MotionConfig {
  const MotionConfig({
    this.sensitivity = 1.0,
    this.deadZone = 0.05,
    this.acceleration = 1.4,
    this.smoothing = 0.35,
    this.invertX = false,
    this.invertY = false,
  });

  /// Overall pointer speed multiplier. Range: 0.1 (very slow) - 3.0 (very fast).
  final double sensitivity;

  /// How much involuntary micro-tremor to ignore before the cursor starts
  /// moving at all. Range: 0.0 (none) - 1.0 (maximum).
  final double deadZone;

  /// Exponent applied to motion magnitude: > 1 makes small movements more
  /// precise while fast flicks travel proportionally further. Range: 1.0 - 3.0.
  final double acceleration;

  /// Exponential smoothing factor applied to the output. Higher values
  /// remove more jitter at the cost of a touch more latency. Range: 0.0 - 0.95.
  final double smoothing;

  final bool invertX;
  final bool invertY;
}
