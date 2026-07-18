import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';

/// Owns [AppSettings], persisting every change immediately via
/// [UpdateSettings]. Reads its initial value synchronously from
/// [GetSettings] since [SharedPreferences] is already warm by the time the
/// provider tree is built (see `main()`).
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final result = ref.watch(getSettingsUseCaseProvider).call();
    return result.fold(onSuccess: (s) => s, onFailure: (_) => AppSettings.defaults());
  }

  Future<void> _persist() => ref.read(updateSettingsUseCaseProvider).call(state);

  Future<void> setSensitivity(double value) async {
    state = state.copyWith(sensitivity: value.clamp(0.1, 3.0).toDouble());
    await _persist();
  }

  Future<void> setDeadZone(double value) async {
    state = state.copyWith(deadZone: value.clamp(0.0, 1.0).toDouble());
    await _persist();
  }

  Future<void> setAcceleration(double value) async {
    state = state.copyWith(acceleration: value.clamp(1.0, 3.0).toDouble());
    await _persist();
  }

  Future<void> setSmoothing(double value) async {
    state = state.copyWith(smoothing: value.clamp(0.0, 0.95).toDouble());
    await _persist();
  }

  Future<void> setInvertX(bool value) async {
    state = state.copyWith(invertX: value);
    await _persist();
  }

  Future<void> setInvertY(bool value) async {
    state = state.copyWith(invertY: value);
    await _persist();
  }

  Future<void> setLeftHandedMode(bool value) async {
    state = state.copyWith(leftHandedMode: value);
    await _persist();
  }

  Future<void> setAmoledDarkMode(bool value) async {
    state = state.copyWith(amoledDarkMode: value);
    await _persist();
  }

  Future<void> setAutoReconnect(bool value) async {
    state = state.copyWith(autoReconnect: value);
    await _persist();
  }

  Future<void> reset() async {
    final result = await ref.read(resetSettingsUseCaseProvider).call();
    result.fold(onSuccess: (s) => state = s, onFailure: (_) {});
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
