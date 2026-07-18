import 'package:flutter/material.dart';

import '../../../../core/widgets/section_label.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: 10),
        for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
      ],
    );
  }
}
