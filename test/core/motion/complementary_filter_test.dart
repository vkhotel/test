import 'package:flutter_test/flutter_test.dart';
import 'package:aerotouch/core/motion/complementary_filter.dart';

void main() {
  group('ComplementaryFilter', () {
    test('starts at zero pitch and roll', () {
      final filter = ComplementaryFilter();
      expect(filter.pitch, 0);
      expect(filter.roll, 0);
    });

    test('stays near zero when the phone is flat and perfectly still', () {
      final filter = ComplementaryFilter();

      // Flat on a table: no rotation, gravity straight down the Z axis.
      for (var i = 0; i < 200; i++) {
        filter.update(
          gyroX: 0,
          gyroY: 0,
          accelX: 0,
          accelY: 0,
          accelZ: 9.80665,
          dt: 0.01,
        );
      }

      expect(filter.pitch, closeTo(0, 0.01));
      expect(filter.roll, closeTo(0, 0.01));
    });

    test('gyro integration accumulates rotation over time for a steady turn', () {
      final filter = ComplementaryFilter(gyroTrust: 0.999);

      // A steady 1 rad/s turn with gravity held constant (as if spun on a
      // rig) for half a second should integrate to roughly 0.5 rad, since
      // gyroTrust close to 1 heavily favors the integrated gyro signal.
      for (var i = 0; i < 50; i++) {
        filter.update(
          gyroX: 1.0,
          gyroY: 0,
          accelX: 0,
          accelY: 0,
          accelZ: 9.80665,
          dt: 0.01,
        );
      }

      expect(filter.pitch, closeTo(0.5, 0.05));
    });

    test('reset() zeroes the estimate', () {
      final filter = ComplementaryFilter();
      filter.update(gyroX: 1, gyroY: 1, accelX: 0, accelY: 0, accelZ: 9.8, dt: 0.1);
      expect(filter.pitch, isNot(0));

      filter.reset();
      expect(filter.pitch, 0);
      expect(filter.roll, 0);
    });

    test('rejects an invalid gyroTrust outside (0, 1)', () {
      expect(() => ComplementaryFilter(gyroTrust: 1.0), throwsA(isA<AssertionError>()));
      expect(() => ComplementaryFilter(gyroTrust: 0.0), throwsA(isA<AssertionError>()));
    });
  });
}
