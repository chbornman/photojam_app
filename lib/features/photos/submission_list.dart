// submission_list.dart
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/features/photos/submission_item.dart';

class SubmissionList extends StatelessWidget {
  final List<Submission> submissions;

  const SubmissionList({
    super.key,
    required this.submissions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: submissions.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemBuilder: (context, index) => SubmissionItem(
        submission: submissions[index],
        index: index,
      ),
    );
  }
}