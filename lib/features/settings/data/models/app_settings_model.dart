import '../../domain/entities/app_settings.dart';

/// [AppSettings] plus JSON (de)serialization for [SharedPreferences] storage.
class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.sensitivity,
    required super.deadZone,
    required super.acceleration,
    required super.smoothing,
    required super.invertX,
    required super.invertY,
    required super.leftHandedMode,
    required super.amoledDarkMode,
    required super.autoReconnect,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(
        sensitivity: settings.sensitivity,
        deadZone: settings.deadZone,
        acceleration: settings.acceleration,
        smoothing: settings.smoothing,
        invertX: settings.invertX,
        invertY: settings.invertY,
        leftHandedMode: settings.leftHandedMode,
        amoledDarkMode: settings.amoledDarkMode,
        autoReconnect: settings.autoReconnect,
      );

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettingsModel(
      sensitivity: _numOr(json, 'sensitivity', defaults.sensitivity),
      deadZone: _numOr(json, 'deadZone', defaults.deadZone),
      acceleration: _numOr(json, 'acceleration', defaults.acceleration),
      smoothing: _numOr(json, 'smoothing', defaults.smoothing),
      invertX: _boolOr(json, 'invertX', defaults.invertX),
      invertY: _boolOr(json, 'invertY', defaults.invertY),
      leftHandedMode: _boolOr(json, 'leftHandedMode', defaults.leftHandedMode),
      amoledDarkMode: _boolOr(json, 'amoledDarkMode', defaults.amoledDarkMode),
      autoReconnect: _boolOr(json, 'autoReconnect', defaults.autoReconnect),
    );
  }

  /// Reads a numeric field defensively: a wrong-typed or missing value falls
  /// back to [fallback] instead of throwing, since this is parsing whatever
  /// was last persisted on disk and must never crash app startup.
  static double _numOr(Map<String, dynamic> json, String key, double fallback) {
    final value = json[key];
    return value is num ? value.toDouble() : fallback;
  }

  static bool _boolOr(Map<String, dynamic> json, String key, bool fallback) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  Map<String, dynamic> toJson() => {
        'sensitivity': sensitivity,
        'deadZone': deadZone,
        'acceleration': acceleration,
        'smoothing': smoothing,
        'invertX': invertX,
        'invertY': invertY,
        'leftHandedMode': leftHandedMode,
        'amoledDarkMode': amoledDarkMode,
        'autoReconnect': autoReconnect,
      };
}
