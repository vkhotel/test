import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized type scale. Everything routes through [GoogleFonts.inter] so
/// the whole app shares one clean, modern typeface instead of the platform
/// default.
abstract final class AppTextStyles {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle heroTitle = _base(
    size: 46,
    weight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.05,
  );

  static TextStyle heroSubtitle = _base(
    size: 16,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle sectionTitle = _base(
    size: 13,
    weight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.4,
  );

  static TextStyle titleLarge = _base(size: 22, weight: FontWeight.w700);
  static TextStyle titleMedium = _base(size: 17, weight: FontWeight.w600);

  static TextStyle body = _base(size: 15, weight: FontWeight.w400);
  static TextStyle bodyMuted = _base(
    size: 14,
    weight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle statValue = _base(size: 20, weight: FontWeight.w700);
  static TextStyle statLabel = _base(
    size: 11,
    weight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.6,
  );

  static TextStyle button = _base(
    size: 16,
    weight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle caption = _base(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
