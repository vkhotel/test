import 'package:flutter/services.dart';

/// Centralizes every haptic pulse the app fires, so the "feel" of clicks,
/// scrolls, and connection events can be tuned in one place.
class HapticsService {
  const HapticsService();

  void tap() => HapticFeedback.selectionClick();

  void leftClick() => HapticFeedback.lightImpact();

  void rightClick() => HapticFeedback.mediumImpact();

  void doubleClick() {
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 60), HapticFeedback.lightImpact);
  }

  void dragStart() => HapticFeedback.mediumImpact();

  void dragEnd() => HapticFeedback.lightImpact();

  void navigation() => HapticFeedback.mediumImpact();

  void clutchEngaged() => HapticFeedback.selectionClick();

  void connectionEstablished() => HapticFeedback.heavyImpact();

  void connectionLost() => HapticFeedback.vibrate();
}
