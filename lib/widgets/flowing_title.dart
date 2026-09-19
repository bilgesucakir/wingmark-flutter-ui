import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Large script-font screen title, mirroring the Swift app's shared
/// FlowingTitle view (Font.flowing / SnellRoundhand).
class FlowingTitle extends StatelessWidget {
  const FlowingTitle(this.text, {super.key, this.size = 34});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.flowing(size));
  }
}
