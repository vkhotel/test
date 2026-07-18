import 'package:equatable/equatable.dart';

/// Every user-tunable preference in the app, in one immutable snapshot.
///
/// Ranges (enforced by the sliders in the UI, not re-validated here):
///  * [sensitivity]   0.1 - 3.0, default 1.0
///  * [deadZone]      0.0 - 1.0, default 0.15
///  * [acceleration]  1.0 - 3.0, default 1.4
///  * [smoothing]     0.0 - 0.95, default 0.35
class AppSettings extends Equatable {
  const AppSettings({
    required this.sensitivity,
    required this.deadZone,
    required this.acceleration,
    required this.smoothing,
    required this.invertX,
    required this.invertY,
    required this.leftHandedMode,
    required this.amoledDarkMode,
    required this.autoReconnect,
  });

  factory AppSettings.defaults() => const AppSettings(
        sensitivity: 1.0,
        deadZone: 0.15,
        acceleration: 1.4,
        smoothing: 0.35,
        invertX: false,
        invertY: false,
        leftHandedMode: false,
        amoledDarkMode: true,
        autoReconnect: true,
      );

  final double sensitivity;
  final double deadZone;
  final double acceleration;
  final double smoothing;
  final bool invertX;
  final bool invertY;
  final bool leftHandedMode;

  /// Pure-black vs. slightly-lifted dark theme - see `AppTheme.build`.
  final bool amoledDarkMode;
  final bool autoReconnect;

  AppSettings copyWith({
    double? sensitivity,
    double? deadZone,
    double? acceleration,
    double? smoothing,
    bool? invertX,
    bool? invertY,
    bool? leftHandedMode,
    bool? amoledDarkMode,
    bool? autoReconnect,
  }) {
    return AppSettings(
      sensitivity: sensitivity ?? this.sensitivity,
      deadZone: deadZone ?? this.deadZone,
      acceleration: acceleration ?? this.acceleration,
      smoothing: smoothing ?? this.smoothing,
      invertX: invertX ?? this.invertX,
      invertY: invertY ?? this.invertY,
      leftHandedMode: leftHandedMode ?? this.leftHandedMode,
      amoledDarkMode: amoledDarkMode ?? this.amoledDarkMode,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  @override
  List<Object?> get props => [
        sensitivity,
        deadZone,
        acceleration,
        smoothing,
        invertX,
        invertY,
        leftHandedMode,
        amoledDarkMode,
        autoReconnect,
      ];
}
