import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';

Widget StandardButton({
  required Widget label,
  required VoidCallback? onPressed,
  Widget? icon, // Optional icon parameter
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          minimumSize: Size(120,
              defaultButtonHeight), // Set a more reasonable width here if needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultCornerRadius),
          ),
        ),
        child: icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  label,
                ],
              ),
      ),
    ),
  );
}
