import 'package:flutter/material.dart';
import 'package:photojam_app/config/app_constants.dart';

class StandardButton extends StatelessWidget {
  final Widget label;
  final VoidCallback? onPressed;
  final Widget? icon;

  const StandardButton({super.key, 
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary, 
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: Size(120, AppConstants.defaultButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          child: icon == null
              ? label
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) icon!,
                    const SizedBox(width: 8),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}