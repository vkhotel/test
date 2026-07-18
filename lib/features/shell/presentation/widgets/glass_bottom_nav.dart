import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const _navItems = <_NavItem>[
  _NavItem(icon: Icons.home_rounded, label: 'Home'),
  _NavItem(icon: Icons.tune_rounded, label: 'Settings'),
  _NavItem(icon: Icons.info_outline_rounded, label: 'About'),
];

/// A floating, blurred pill nav bar with a gradient indicator that slides
/// between tabs - the deliberate alternative to Flutter's stock
/// [BottomNavigationBar], which would clash with the glassmorphism brief.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({super.key, required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: GlassContainer(
          borderRadius: 28,
          blurSigma: 22,
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _navItems.length;
              return SizedBox(
                height: 58,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * currentIndex,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: AppGradients.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _navItems.length; i++)
                          Expanded(
                            child: _NavButton(
                              item: _navItems[i],
                              selected: i == currentIndex,
                              onTap: () => onChanged(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
