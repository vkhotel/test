import 'package:flutter_test/flutter_test.dart';
import 'package:aerotouch/features/settings/data/models/app_settings_model.dart';
import 'package:aerotouch/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('defaults() produces sane, in-range values', () {
      final defaults = AppSettings.defaults();

      expect(defaults.sensitivity, inInclusiveRange(0.1, 3.0));
      expect(defaults.deadZone, inInclusiveRange(0.0, 1.0));
      expect(defaults.acceleration, inInclusiveRange(1.0, 3.0));
      expect(defaults.smoothing, inInclusiveRange(0.0, 0.95));
      expect(defaults.invertX, isFalse);
      expect(defaults.invertY, isFalse);
      expect(defaults.autoReconnect, isTrue);
    });

    test('copyWith only changes the requested fields', () {
      final defaults = AppSettings.defaults();
      final updated = defaults.copyWith(sensitivity: 2.0, invertX: true);

      expect(updated.sensitivity, 2.0);
      expect(updated.invertX, isTrue);
      expect(updated.deadZone, defaults.deadZone);
      expect(updated.leftHandedMode, defaults.leftHandedMode);
    });

    test('two settings with identical fields are equal (Equatable)', () {
      final a = AppSettings.defaults();
      final b = AppSettings.defaults();
      expect(a, equals(b));
    });
  });

  group('AppSettingsModel', () {
    test('round-trips through JSON without losing data', () {
      final original = AppSettingsModel.fromEntity(
        AppSettings.defaults().copyWith(
          sensitivity: 1.75,
          deadZone: 0.4,
          acceleration: 2.1,
          smoothing: 0.6,
          invertX: true,
          invertY: true,
          leftHandedMode: true,
          amoledDarkMode: false,
          autoReconnect: false,
        ),
      );

      final restored = AppSettingsModel.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('fromJson falls back to defaults for missing/malformed fields', () {
      final restored = AppSettingsModel.fromJson(const {'sensitivity': 'not a number'});
      expect(restored.sensitivity, AppSettings.defaults().sensitivity);
    });
  });
}
