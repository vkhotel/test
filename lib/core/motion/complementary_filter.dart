import 'dart:math' as math;

/// A classic complementary filter for orientation (pitch/roll) estimation.
///
/// IMUs give you two flawed but complementary sources of truth:
///  * The **gyroscope** is smooth and low-latency, but integrating its
///    angular rate over time slowly accumulates drift.
///  * The **accelerometer** gives an absolute tilt reading (via the gravity
///    vector) with no long-term drift, but it's noisy and gets corrupted by
///    any real acceleration (shaking, bumps, etc).
///
/// The complementary filter fuses them with a single trust weight: mostly
/// trust the gyroscope from one instant to the next (it's smooth), but keep
/// gently nudging the estimate back towards whatever the accelerometer says
/// so errors never accumulate indefinitely. This is far cheaper than a full
/// Madgwick/Mahony AHRS filter while still eliminating drift, which is all
/// AeroTouch needs since it only tracks 2-DOF pointer motion, not a full 3D
/// attitude/quaternion.
class ComplementaryFilter {
  ComplementaryFilter({this.gyroTrust = 0.98})
      : assert(gyroTrust > 0 && gyroTrust < 1, 'gyroTrust must be in (0, 1)');

  /// Weight given to the gyroscope-integrated angle on each update.
  /// The remaining `1 - gyroTrust` is given to the accelerometer's estimate.
  final double gyroTrust;

  double _pitch = 0; // radians, rotation about the device's X axis.
  double _roll = 0; // radians, rotation about the device's Y axis.

  double get pitch => _pitch;
  double get roll => _roll;

  /// Advances the filter by one IMU sample.
  ///
  /// [gyroX] / [gyroY] are angular rates in rad/s from the gyroscope.
  /// [accelX] / [accelY] / [accelZ] are accelerometer readings in m/s^2
  /// (gravity included). [dt] is the elapsed time since the previous
  /// update, in seconds.
  void update({
    required double gyroX,
    required double gyroY,
    required double accelX,
    required double accelY,
    required double accelZ,
    required double dt,
  }) {
    // Tilt implied purely by gravity, ignoring rotation history.
    final accelPitch = math.atan2(-accelX, math.sqrt(accelY * accelY + accelZ * accelZ));
    final accelRoll = math.atan2(accelY, accelZ);

    _pitch = gyroTrust * (_pitch + gyroX * dt) + (1 - gyroTrust) * accelPitch;
    _roll = gyroTrust * (_roll + gyroY * dt) + (1 - gyroTrust) * accelRoll;
  }

  void reset() {
    _pitch = 0;
    _roll = 0;
  }
}
