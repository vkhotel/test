import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the single Material 3 [ThemeData] AeroTouch uses everywhere.
///
/// The product spec calls for an always-dark, glassmorphic look, so there is
/// no light theme. The [amoled] flag (driven by the "Dark mode" setting)
/// switches between a pure-black canvas and a very slightly lifted
/// "twilight" canvas for people who find true black harsh on OLED panels -
/// both are still unmistakably dark.
abstract final class AppTheme {
  static ThemeData build({bool amoled = true}) {
    final background = amoled ? AppColors.background : const Color(0xFF111114);

    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.purple,
      secondary: AppColors.blue,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: AppColors.purple.withValues(alpha: 0.08),
      splashColor: AppColors.blue.withValues(alpha: 0.12),
      fontFamily: AppTextStyles.body.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heroTitle,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.button,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.purple,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: Colors.white,
        overlayColor: AppColors.purple.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.surfaceElevated,
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.purple
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

/// A gentle cross-fade transition used for the bottom-nav shell and for
/// entering/leaving Mouse Mode, instead of the default Material slide.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
