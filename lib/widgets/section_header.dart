import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Uppercase caption used above grouped form sections, mirroring iOS
/// Form section headers.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
