import 'package:flutter/material.dart';
import 'package:photojam_app/standard_button.dart';

class StandardDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String submitButtonLabel;
  final VoidCallback submitButtonOnPressed;

  const StandardDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.submitButtonLabel,
    required this.submitButtonOnPressed,
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
            StandardButton(
              label: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8), // Add some space between the buttons
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