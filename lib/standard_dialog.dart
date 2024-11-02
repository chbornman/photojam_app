import 'package:flutter/material.dart';

class StandardDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const StandardDialog({
    Key? key,
    required this.title,
    required this.content,
    this.actions = const [],
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
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: action,
            );
          }).toList(),
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