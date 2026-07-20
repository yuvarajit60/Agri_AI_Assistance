import 'package:flutter/material.dart';

/// Standard call-to-action button with a built-in loading state so every
/// async action (login, OTP verify, save) gets consistent affordance
/// instead of each screen rolling its own spinner-swap logic.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                outlined ? Theme.of(context).colorScheme.primary : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
              // Flexible (not a bare Text) so longer translations wrap onto a
              // second line instead of overflowing the button's fixed width.
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return outlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}
