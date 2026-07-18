import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// A small, letter-spaced uppercase label used to introduce a group of
/// settings or a section of the Home screen (e.g. "DEVICE STATUS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text.toUpperCase(), style: AppTextStyles.sectionTitle),
        if (trailing != null) trailing!,
      ],
    );
  }
}
