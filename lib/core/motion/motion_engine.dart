import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../constants/app_constants.dart';
import 'complementary_filter.dart';
import 'motion_models.dart';

/// Converts raw phone motion into smooth, precise cursor deltas.
///
/// Pipeline, run once per gyroscope sample (~every 10ms / 100Hz):
///  1. **Sensor fusion** - a [ComplementaryFilter] fuses gyro + accelerometer
///     into a stable pitch/roll estimate, which also lets us reliably detect
///     when the phone is genuinely at rest (as opposed to just moving slowly).
///  2. **Drift-bias learning** - while at rest, the gyroscope's zero-rate
///     bias is learned and subtracted from every future sample, so the
///     cursor never creeps while the phone sits still on a desk.
///  3. **Adaptive dead zone** - tiny hand tremor below a configurable
///     threshold is discarded before it ever becomes cursor movement.
///  4. **Motion acceleration** - a power curve keeps slow movements precise
///     while fast flicks travel proportionally further.
///  5. **Exponential smoothing** - a one-pole low-pass filter removes
///     high-frequency jitter; because it's exponential, releasing motion
///     also *decelerates* the cursor smoothly instead of stopping dead.
///
/// The engine only *emits* deltas while [engageClutch] has been called and
/// [disengageClutch] has not - see the Smart Clutch feature in
/// `features/mouse_control`. Sampling itself never stops while [start] is
/// active, so the bias/orientation estimate stays warm across clutch cycles.
class MotionEngine {
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final StreamController<MotionDelta> _deltaController = StreamController<MotionDelta>.broadcast();
  final StreamController<double> _fpsController = StreamController<double>.broadcast();

  /// Stream of cursor deltas, only emitted while the Smart Clutch is engaged.
  Stream<MotionDelta> get deltaStream => _deltaController.stream;

  /// Stream of the actual achieved sample rate, updated roughly once/second.
  Stream<double> get fpsStream => _fpsController.stream;

  MotionConfig _config = const MotionConfig();
  bool _clutchEngaged = false;
  bool _running = false;

  final ComplementaryFilter _fusion = ComplementaryFilter();

  // --- Gyroscope drift-bias learning ---------------------------------------
  final List<double> _stillGyroX = [];
  final List<double> _stillGyroY = [];
  double _gyroXBias = 0;
  double _gyroYBias = 0;

  // --- Smoothing state ------------------------------------------------------
  double _smoothDx = 0;
  double _smoothDy = 0;

  // --- Latest accelerometer sample (accelerometer + gyro arrive on separate
  // streams at their own cadence; we always fuse against the freshest accel
  // reading available when a gyro sample arrives). ---------------------------
  double _lastAccelX = 0;
  double _lastAccelY = 0;
  double _lastAccelZ = 9.80665;

  DateTime? _lastSampleTime;
  int _sampleCountThisWindow = 0;
  DateTime _fpsWindowStart = DateTime.now();
  double _achievedFps = 0;

  double get achievedFps => _achievedFps;
  double get pitch => _fusion.pitch;
  double get roll => _fusion.roll;

  /// Pushes new tuning parameters (from Settings) into the engine. Safe to
  /// call at any time, including mid-gesture.
  void updateConfig(MotionConfig config) {
    _config = config;
  }

  /// Starts reading the IMU at [AppConstants.sensorSampleRateHz]. No cursor
  /// deltas are emitted until [engageClutch] is also called.
  void start() {
    if (_running) return;
    _running = true;
    _lastSampleTime = null;

    _accelSub = accelerometerEventStream(
      samplingPeriod: AppConstants.sensorSamplingPeriod,
    ).listen(_onAccelerometer, onError: (Object _, StackTrace __) {});

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: AppConstants.sensorSamplingPeriod,
    ).listen(_onGyroscope, onError: (Object _, StackTrace __) {});
  }

  /// Stops all sensor subscriptions. Call when leaving Mouse Mode entirely.
  void stop() {
    _running = false;
    _gyroSub?.cancel();
    _accelSub?.cancel();
    _gyroSub = null;
    _accelSub = null;
    _fusion.reset();
    _stillGyroX.clear();
    _stillGyroY.clear();
  }

  /// Smart Clutch: call when a finger touches down. The cursor starts
  /// receiving deltas again from this instant - it never "jumps" to catch up
  /// on motion that happened while the clutch was disengaged, because
  /// samples during that time were fused (for drift correction) but never
  /// emitted.
  void engageClutch() {
    _clutchEngaged = true;
  }

  /// Smart Clutch: call when the last finger lifts. The cursor freezes in
  /// place exactly like lifting a physical mouse off the desk to reposition
  /// your hand.
  void disengageClutch() {
    _clutchEngaged = false;
    // Reset smoothing so we don't carry stale momentum into the next
    // clutch-engaged segment, which would otherwise cause a small unwanted
    // "kick" the instant the finger touches back down.
    _smoothDx = 0;
    _smoothDy = 0;
  }

  bool get isClutchEngaged => _clutchEngaged;

  void _onAccelerometer(AccelerometerEvent event) {
    _lastAccelX = event.x;
    _lastAccelY = event.y;
    _lastAccelZ = event.z;
  }

  void _onGyroscope(GyroscopeEvent event) {
    final now = DateTime.now();
    final dt = _lastSampleTime == null
        ? 1 / AppConstants.sensorSampleRateHz
        : now.difference(_lastSampleTime!).inMicroseconds / 1e6;
    _lastSampleTime = now;

    // Guard against absurd dt values (e.g. right after a debugger pause or
    // an app resume) which would otherwise cause one giant cursor jump.
    final safeDt = dt.clamp(0.0, 0.05).toDouble();

    _fusion.update(
      gyroX: event.x,
      gyroY: event.y,
      accelX: _lastAccelX,
      accelY: _lastAccelY,
      accelZ: _lastAccelZ,
      dt: safeDt,
    );

    _learnGyroBias(event.x, event.y);

    // event.y -> tilting the phone left/right (yaw) drives horizontal
    // cursor motion. event.x -> tilting up/down (pitch) drives vertical
    // cursor motion. This mapping matches holding the phone upright, face
    // up, like steering a remote; invertX/invertY in Settings flips it for
    // other grips without touching this code.
    final rateYaw = event.y - _gyroYBias;
    final ratePitch = event.x - _gyroXBias;

    _process(rateYaw, ratePitch);
    _trackFps();
  }

  void _learnGyroBias(double gyroX, double gyroY) {
    final accelMagnitude = math.sqrt(
      _lastAccelX * _lastAccelX + _lastAccelY * _lastAccelY + _lastAccelZ * _lastAccelZ,
    );
    final looksStationary =
        (accelMagnitude - 9.80665).abs() < 0.15 && gyroX.abs() < 0.06 && gyroY.abs() < 0.06;

    if (!looksStationary) {
      // Moving - don't let a bias estimate mid-gesture corrupt the average.
      return;
    }

    _stillGyroX.add(gyroX);
    _stillGyroY.add(gyroY);
    if (_stillGyroX.length > AppConstants.biasLearningWindow) {
      _stillGyroX.removeAt(0);
    }
    if (_stillGyroY.length > AppConstants.biasLearningWindow) {
      _stillGyroY.removeAt(0);
    }

    if (_stillGyroX.length >= AppConstants.biasLearningWindow) {
      _gyroXBias = _stillGyroX.reduce((a, b) => a + b) / _stillGyroX.length;
      _gyroYBias = _stillGyroY.reduce((a, b) => a + b) / _stillGyroY.length;
    }
  }

  /// Pixels-per-(rad/s) scaling so the default sensitivity feels comfortable
  /// on a typical 1080p+ display. Exposed as a constant rather than a magic
  /// number sprinkled inline.
  static const double _baseScale = 210.0;

  void _process(double rateYaw, double ratePitch) {
    // Adaptive dead zone: a small fixed noise floor (sensor noise always
    // present) plus a user-configurable band on top of it.
    const noiseFloor = 0.012;
    final deadZone = noiseFloor + _config.deadZone * 0.18;

    final rawX = rateYaw.abs() < deadZone ? 0.0 : rateYaw;
    final rawY = ratePitch.abs() < deadZone ? 0.0 : ratePitch;

    double accelerationCurve(double v) {
      if (v == 0) return 0;
      final sign = v.isNegative ? -1.0 : 1.0;
      return sign * math.pow(v.abs(), _config.acceleration).toDouble();
    }

    double outX = accelerationCurve(rawX) * _baseScale * _config.sensitivity;
    double outY = accelerationCurve(rawY) * _baseScale * _config.sensitivity;

    if (_config.invertX) outX = -outX;
    if (_config.invertY) outY = -outY;

    // Exponential smoothing (one-pole low pass). Because it's exponential
    // rather than a hard cutoff, this doubles as the "motion deceleration"
    // behavior: once real motion stops, the smoothed output decays toward
    // zero over a few frames instead of stopping instantly.
    final smoothing = _config.smoothing.clamp(0.0, 0.95).toDouble();
    _smoothDx = _smoothDx * smoothing + outX * (1 - smoothing);
    _smoothDy = _smoothDy * smoothing + outY * (1 - smoothing);

    if (!_clutchEngaged) return;
    if (_smoothDx.abs() < 0.0005 && _smoothDy.abs() < 0.0005) return;

    _deltaController.add(MotionDelta(dx: _smoothDx, dy: _smoothDy));
  }

  void _trackFps() {
    _sampleCountThisWindow++;
    final elapsed = DateTime.now().difference(_fpsWindowStart);
    if (elapsed.inMilliseconds >= 1000) {
      _achievedFps = _sampleCountThisWindow * 1000 / elapsed.inMilliseconds;
      _sampleCountThisWindow = 0;
      _fpsWindowStart = DateTime.now();
      if (!_fpsController.isClosed) {
        _fpsController.add(_achievedFps);
      }
    }
  }

  void dispose() {
    stop();
    _deltaController.close();
    _fpsController.close();
  }
}
