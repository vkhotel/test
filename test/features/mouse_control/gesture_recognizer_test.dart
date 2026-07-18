import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:aerotouch/core/constants/app_constants.dart';
import 'package:aerotouch/features/mouse_control/domain/entities/mouse_command.dart';
import 'package:aerotouch/features/mouse_control/presentation/controllers/gesture_recognizer.dart';

void main() {
  group('GestureRecognizer', () {
    late List<MouseCommand> commands;
    late List<bool> clutchEvents;
    late GestureRecognizer recognizer;

    setUp(() {
      commands = [];
      clutchEvents = [];
      recognizer = GestureRecognizer(
        onCommand: commands.add,
        onClutchChanged: clutchEvents.add,
      );
    });

    tearDown(() => recognizer.dispose());

    test('a single finger touching down engages the clutch, lifting disengages it', () {
      recognizer.handlePointerDown(1, const Offset(100, 100));
      expect(clutchEvents, [true]);

      recognizer.handlePointerUp(1);
      expect(clutchEvents, [true, false]);
    });

    test('a quick single-finger tap sends a left click after the double-tap window', () async {
      recognizer.handlePointerDown(1, const Offset(100, 100));
      recognizer.handlePointerUp(1);

      await Future<void>.delayed(AppConstants.doubleTapWindow + const Duration(milliseconds: 50));

      expect(commands.whereType<LeftClickCommand>().length, 1);
      expect(commands.whereType<DoubleClickCommand>(), isEmpty);
    });

    test('two quick single-finger taps in the same spot send one double click', () async {
      recognizer.handlePointerDown(1, const Offset(100, 100));
      recognizer.handlePointerUp(1);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      recognizer.handlePointerDown(2, const Offset(102, 101));
      recognizer.handlePointerUp(2);

      await Future<void>.delayed(AppConstants.doubleTapWindow + const Duration(milliseconds: 50));

      expect(commands.whereType<DoubleClickCommand>().length, 1);
      expect(commands.whereType<LeftClickCommand>(), isEmpty);
    });

    test('a quick two-finger tap sends a right click', () {
      recognizer.handlePointerDown(1, const Offset(80, 200));
      recognizer.handlePointerDown(2, const Offset(200, 200));
      recognizer.handlePointerUp(1);
      recognizer.handlePointerUp(2);

      expect(commands.whereType<RightClickCommand>().length, 1);
    });

    test('a held single finger sends left button down, and releasing sends left button up', () async {
      recognizer.handlePointerDown(1, const Offset(100, 100));

      await Future<void>.delayed(AppConstants.longPressDuration + const Duration(milliseconds: 80));

      expect(commands.whereType<LeftButtonDownCommand>().length, 1);

      recognizer.handlePointerUp(1);
      expect(commands.whereType<LeftButtonUpCommand>().length, 1);

      // A long press should never also be reported as a tap.
      expect(commands.whereType<LeftClickCommand>(), isEmpty);
    });

    test('two fingers swiping vertically together send scroll commands', () {
      recognizer.handlePointerDown(1, const Offset(100, 300));
      recognizer.handlePointerDown(2, const Offset(200, 300));

      recognizer.handlePointerMove(1, const Offset(100, 200));
      recognizer.handlePointerMove(2, const Offset(200, 200));

      expect(commands.whereType<ScrollCommand>(), isNotEmpty);

      recognizer.handlePointerUp(1);
      recognizer.handlePointerUp(2);
    });

    test('three fingers swiping left send a single back command', () {
      recognizer.handlePointerDown(1, const Offset(300, 300));
      recognizer.handlePointerDown(2, const Offset(300, 400));
      recognizer.handlePointerDown(3, const Offset(300, 500));

      recognizer.handlePointerMove(1, const Offset(100, 300));
      recognizer.handlePointerMove(2, const Offset(100, 400));
      recognizer.handlePointerMove(3, const Offset(100, 500));

      expect(commands.whereType<BackCommand>().length, 1);
      expect(commands.whereType<ForwardCommand>(), isEmpty);

      recognizer.handlePointerUp(1);
      recognizer.handlePointerUp(2);
      recognizer.handlePointerUp(3);
    });

    test('left-handed mode swaps single-finger and two-finger tap outcomes', () async {
      recognizer.leftHandedMode = true;

      recognizer.handlePointerDown(1, const Offset(80, 200));
      recognizer.handlePointerDown(2, const Offset(200, 200));
      recognizer.handlePointerUp(1);
      recognizer.handlePointerUp(2);

      expect(commands.whereType<LeftClickCommand>().length, 1);
      expect(commands.whereType<RightClickCommand>(), isEmpty);
    });
  });
}
