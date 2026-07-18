import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';

/// The big "AeroTouch / Precision Motion Mouse" hero at the top of Home.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -40,
          left: -30,
          child: GlowHalo(size: 220),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (rect) => AppGradients.primary.createShader(rect),
                blendMode: BlendMode.srcIn,
                child: Text(AppConstants.appName, style: AppTextStyles.heroTitle),
              ),
              const SizedBox(height: 6),
              Text(AppConstants.appTagline, style: AppTextStyles.heroSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
