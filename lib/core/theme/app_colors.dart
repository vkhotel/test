import 'package:flutter/material.dart';

/// The AeroTouch brand palette: near-black canvas, a purple/blue gradient
/// pair, and semantic status colors used consistently across every feature.
abstract final class AppColors {
  // --- Base canvas ------------------------------------------------------------
  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF141417);
  static const Color surfaceElevated = Color(0xFF1C1C22);

  // --- Brand gradient -----------------------------------------------------
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDeep = Color(0xFF4C1D95);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDeep = Color(0xFF1D4ED8);

  // --- Text -------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // --- Glass surfaces -----------------------------------------------------
  static const Color glassFill = Color(0x14FFFFFF); // ~8% white
  static const Color glassFillStrong = Color(0x22FFFFFF); // ~13% white
  static const Color glassBorder = Color(0x26FFFFFF); // ~15% white

  // --- Status -------------------------------------------------------------
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  /// Maps a normalized latency/quality value to a color, used by the
  /// connection stat tiles (green = great, amber = ok, red = poor).
  static Color qualityColor(double normalizedGoodness) {
    if (normalizedGoodness >= 0.66) return success;
    if (normalizedGoodness >= 0.33) return warning;
    return danger;
  }
}
