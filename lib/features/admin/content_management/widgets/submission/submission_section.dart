// lib/features/admin/content_management/widgets/submission/submission_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/dialogs/create_submission_card.dart';
import 'package:photojam_app/dialogs/delete_submission_card.dart';
import 'package:photojam_app/dialogs/update_submission_card.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';

class SubmissionSection extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const SubmissionSection({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Submissions",
      color: AppConstants.photojamOrange,
      children: [
        CreateSubmissionCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        UpdateSubmissionCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteSubmissionCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
      ],
    );
  }
}