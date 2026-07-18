import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

/// Reads the *phone's* battery level (not the desktop's) so the Home screen
/// can warn the user before the always-on sensors + radio drain it.
class BatteryService {
  BatteryService() : _battery = Battery();

  final Battery _battery;

  Future<int> currentLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1; // Unknown - some emulators/devices don't expose this.
    }
  }

  /// Emits the battery level every [interval], suitable for driving a
  /// lightweight polling loop without needing platform-specific listeners.
  Stream<int> pollEvery(Duration interval) async* {
    while (true) {
      yield await currentLevel();
      await Future<void>.delayed(interval);
    }
  }
}
