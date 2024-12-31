// lib/features/admin/content_management/dialogs/submission/delete_submission_dialog.dart

import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class DeleteSubmissionDialog extends StatefulWidget {
  final Map<String, String> submissionMap;
  final Function(String) onSubmissionDeleted;

  const DeleteSubmissionDialog({
    super.key,
    required this.submissionMap,
    required this.onSubmissionDeleted,
  });

  @override
  State<DeleteSubmissionDialog> createState() => _DeleteSubmissionDialogState();
}

class _DeleteSubmissionDialogState extends State<DeleteSubmissionDialog> {
  String? _selectedSubmissionId;

  void _confirmDeletion() {
    if (_selectedSubmissionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a submission to delete")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text(
          "Are you sure you want to delete this submission?\n\n"
          "ID: $_selectedSubmissionId",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close delete dialog
              widget.onSubmissionDeleted(_selectedSubmissionId!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Delete Submission",
      content: DropdownButtonFormField<String>(
        value: _selectedSubmissionId,
        hint: const Text("Select Submission"),
        items: widget.submissionMap.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.value,
            child: Text(entry.key),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedSubmissionId = value),
      ),
      submitButtonLabel: "Delete",
      submitButtonOnPressed: _confirmDeletion,
    );
  }
}