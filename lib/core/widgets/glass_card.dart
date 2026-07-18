import 'package:flutter/material.dart';

import 'glass_container.dart';

/// A standard content card: rounded, blurred, with comfortable padding.
/// Use this for the majority of surfaces; drop to [GlassContainer] directly
/// only when you need a non-standard shape (e.g. a pill button backdrop).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}
