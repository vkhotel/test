import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Every gradient used in the UI, kept in one place so the "purple gradient,
/// blue accent" brand direction stays consistent across screens.
abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.blue],
  );

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purpleDeep, AppColors.blueDeep],
  );

  /// Soft radial glow used behind the connect button / hero title.
  static RadialGradient heroGlow({double opacity = 0.35}) => RadialGradient(
        colors: [
          AppColors.purple.withValues(alpha: opacity),
          AppColors.blue.withValues(alpha: opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  /// The full-screen backdrop gradient: near-black with a faint purple/blue
  /// wash in the upper corners, evoking depth without ever looking like a
  /// flat Android default background.
  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF14101F),
      AppColors.background,
      Color(0xFF0B1120),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient glassStroke({double opacity = 0.4}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0.02),
        ],
      );
}
