import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// The single building block behind AeroTouch's glassmorphism: a blurred,
/// semi-transparent surface with a soft gradient border and rounded corners.
///
/// Every card, button backdrop, and sheet in the app is built from this
/// widget so the "frosted glass" language stays perfectly consistent.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.blurSigma = 18,
    this.fillColor,
    this.borderOpacity = 0.4,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? fillColor;
  final double borderOpacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.glassFill,
            borderRadius: radius,
            border: Border.all(
              width: 1.2,
              color: AppColors.glassBorder.withValues(alpha: borderOpacity),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                fillColor ?? AppColors.glassFill,
                Colors.black.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );

    final withMargin = margin != null ? Padding(padding: margin!, child: content) : content;

    if (onTap == null) return withMargin;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: withMargin,
      ),
    );
  }
}

/// A subtle animated glow ring, used behind the Connect / Start Mouse
/// buttons and around the connection indicator so key actions feel alive.
class GlowHalo extends StatelessWidget {
  const GlowHalo({
    super.key,
    required this.size,
    this.opacity = 0.35,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.heroGlow(opacity: opacity),
        ),
      ),
    );
  }
}
