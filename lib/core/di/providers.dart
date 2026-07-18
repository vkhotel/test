import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/battery_service.dart';
import '../services/haptics_service.dart';

/// Overridden in `main()` with a real [SharedPreferences] instance obtained
/// via `await SharedPreferences.getInstance()`. Reading it before that
/// override is a programming error, hence the loud [UnimplementedError].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp().',
  );
});

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return const HapticsService();
});

final batteryServiceProvider = Provider<BatteryService>((ref) {
  final service = BatteryService();
  return service;
});
