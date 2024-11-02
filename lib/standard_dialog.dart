import 'package:flutter/material.dart';
import 'package:photojam_app/standard_button.dart';

class StandardDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String submitButtonLabel;
  final VoidCallback submitButtonOnPressed;
  final bool showCancelButton; // New parameter to control cancel button visibility

  const StandardDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.submitButtonLabel,
    required this.submitButtonOnPressed,
    this.showCancelButton = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: content,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showCancelButton) // Conditionally show the Cancel button
              StandardButton(
                label: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            if (showCancelButton) const SizedBox(width: 8), // Add space only if Cancel button is shown
            StandardButton(
              label: Text(submitButtonLabel),
              onPressed: submitButtonOnPressed,
            ),
          ],
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
    );
  }
}