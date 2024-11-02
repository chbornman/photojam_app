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
          minimumSize: const Size(double.infinity, defaultButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultCornerRadius),
          ),
        ),
        child: icon == null
            ? label // If no icon, just show the label
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon, // Display the icon
                  const SizedBox(width: 8), // Space between icon and label
                  label,
                ],
              ),
      ),
    ),
  );
}