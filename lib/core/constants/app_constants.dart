/// Centralized, named constants used across every feature.
///
/// Keeping these in one place means tuning the product (e.g. changing the
/// discovery port, or how long a tap can last) never requires hunting
/// through unrelated files.
class AppConstants {
  const AppConstants._();

  // --- App metadata ---------------------------------------------------------
  static const String appName = 'AeroTouch';
  static const String appTagline = 'Precision Motion Mouse';

  // --- Networking -------------------------------------------------------------
  /// Default TCP port the desktop receiver listens for WebSocket connections on.
  static const int defaultServerPort = 58712;

  /// UDP port used for LAN auto-discovery broadcasts.
  static const int discoveryPort = 58008;

  static const Duration discoveryTimeout = Duration(seconds: 4);
  static const Duration heartbeatInterval = Duration(seconds: 2);
  static const Duration heartbeatTimeout = Duration(seconds: 6);
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Base delay for exponential-backoff auto-reconnect attempts.
  static const Duration reconnectBaseDelay = Duration(milliseconds: 800);
  static const Duration reconnectMaxDelay = Duration(seconds: 10);
  static const int maxReconnectAttempts = 8;

  // --- Motion engine ----------------------------------------------------------
  /// Target IMU sampling rate, in Hz, per the product spec.
  static const int sensorSampleRateHz = 100;
  static const Duration sensorSamplingPeriod =
      Duration(microseconds: 1000000 ~/ sensorSampleRateHz);

  /// Number of consecutive "still" samples used to learn gyroscope zero-rate
  /// bias, so the cursor never drifts while the phone is stationary.
  static const int biasLearningWindow = 60;

  // --- Gesture timings --------------------------------------------------------
  static const Duration tapMaxDuration = Duration(milliseconds: 200);
  static const double tapMaxSlopPx = 14.0;
  static const Duration doubleTapWindow = Duration(milliseconds: 320);
  static const Duration longPressDuration = Duration(milliseconds: 480);
  static const double swipeThresholdPx = 36.0;
  static const double pinchThresholdPx = 28.0;

  // --- Persistence keys ---------------------------------------------------
  static const String prefsSettingsKey = 'aerotouch.settings.v1';
  static const String prefsLastHostKey = 'aerotouch.last_host.v1';
}
