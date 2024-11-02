import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';

Widget standardButton({
  required String label,
  required VoidCallback? onPressed, // onPressed can still be nullable for disabling
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor, // Fixed color from constants
          foregroundColor: Colors.black, // Fixed text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultCornerRadius), // Fixed corner radius
          ),
        ),
        child: Text(label),
      ),
    ),
  );
}