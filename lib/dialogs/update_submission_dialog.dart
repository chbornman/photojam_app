// lib/features/admin/content_management/dialogs/submission/update_submission_dialog.dart

import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class UpdateSubmissionDialog extends StatefulWidget {
  final Submission submission;
  final Function(Map<String, dynamic>) onSubmissionUpdated;

  const UpdateSubmissionDialog({
    super.key,
    required this.submission,
    required this.onSubmissionUpdated,
  });

  @override
  State<UpdateSubmissionDialog> createState() => _UpdateSubmissionDialogState();
}

class _UpdateSubmissionDialogState extends State<UpdateSubmissionDialog> {
  late TextEditingController _commentController;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.submission.comment);
    _photos = List.from(widget.submission.photos);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Map<String, dynamic> updatedData = {
      "photos": _photos,
      "comment": _commentController.text,
    };

    widget.onSubmissionUpdated(updatedData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Update Submission",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jam ID: ${widget.submission.jamId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'User ID: ${widget.submission.userId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          // Photo management UI would go here
        ],
      ),
      submitButtonLabel: "Update",
      submitButtonOnPressed: _submit,
    );
  }
}