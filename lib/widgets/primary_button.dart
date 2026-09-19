import 'package:flutter/material.dart';

/// Elevated button that shows a spinner and disables itself while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Text(label),
    );
  }
}
