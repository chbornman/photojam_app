// lib/features/admin/content_management/widgets/submission/delete_submission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/content_management/actions/submission_management_actions.dart';

class DeleteSubmissionCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DeleteSubmissionCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.delete,
      title: "Delete Submission",
      onTap: () => SubmissionManagementActions.fetchAndOpenDeleteSubmissionDialog(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}