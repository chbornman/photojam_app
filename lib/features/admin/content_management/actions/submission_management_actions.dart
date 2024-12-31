import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/dialogs/delete_submission_dialog.dart';
import 'package:photojam_app/dialogs/update_submission_dialog.dart';

class SubmissionManagementActions {

  static Future<void> fetchAndOpenUpdateSubmissionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching submissions for update dialog');
      final submissionsAsync = ref.read(submissionsProvider);

      submissionsAsync.when(
        data: (submissions) {
          if (!context.mounted) return;

          if (submissions.isEmpty) {
            onMessage("No submissions available", isError: true);
            return;
          }

          final submissionMap = {
            for (var sub in submissions) 
              '${sub.jamId} - ${sub.dateCreation.toString()}': sub.id
          };
          
          LogService.instance.info('Found ${submissions.length} submissions');

          _openSubmissionSelectionDialog(
            context: context,
            ref: ref,
            submissionMap: submissionMap,
            onLoading: onLoading,
            onMessage: onMessage,
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching submissions: $error');
          onMessage("Error fetching submissions: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenUpdateSubmissionDialog: $e');
      onMessage("Error fetching submissions", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> fetchAndOpenDeleteSubmissionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching submissions for delete dialog');
      final submissionsAsync = ref.read(submissionsProvider);

      submissionsAsync.when(
        data: (submissions) {
          if (!context.mounted) return;

          final submissionMap = {
            for (var sub in submissions)
              '${sub.jamId} - ${sub.dateCreation.toString()}': sub.id
          };

          showDialog(
            context: context,
            builder: (context) => DeleteSubmissionDialog(
              submissionMap: submissionMap,
              onSubmissionDeleted: (submissionId) async {
                try {
                  LogService.instance.info('Deleting submission: $submissionId');
                  await ref.read(submissionsProvider.notifier).deleteSubmission(submissionId);
                  onMessage("Submission deleted successfully");
                } catch (e) {
                  LogService.instance.error('Error deleting submission: $e');
                  onMessage("Error deleting submission: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching submissions: $error');
          onMessage("Error fetching submissions: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenDeleteSubmissionDialog: $e');
      onMessage("Error fetching submissions", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static void _openSubmissionSelectionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, String> submissionMap,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    String? selectedId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Submission to Update"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedId,
              hint: const Text("Select Submission"),
              items: submissionMap.keys.map((display) {
                return DropdownMenuItem(
                  value: display,
                  child: Text(display),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedId = value),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (selectedId != null) {
                _handleSubmissionSelection(
                  context: context,
                  ref: ref,
                  submissionId: submissionMap[selectedId]!,
                  onLoading: onLoading,
                  onMessage: onMessage,
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  static void _handleSubmissionSelection({
    required BuildContext context,
    required WidgetRef ref,
    required String submissionId,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    Navigator.of(context).pop();

    ref.read(submissionByIdProvider(submissionId)).when(
      data: (submission) {
        if (submission == null) {
          LogService.instance.error('Submission not found: $submissionId');
          onMessage("Submission not found", isError: true);
          return;
        }

        showDialog(
          context: context,
          builder: (context) => UpdateSubmissionDialog(
            submission: submission,
            onSubmissionUpdated: (updatedData) async {
              try {
                LogService.instance.info('Updating submission with data: $updatedData');
                await ref.read(submissionsProvider.notifier).updateSubmission(
                  submissionId: submissionId,
                  photos: updatedData['photos'],
                  comment: updatedData['comment'],
                );
                onMessage("Submission updated successfully");
              } catch (e) {
                LogService.instance.error('Error updating submission: $e');
                onMessage("Error updating submission: $e", isError: true);
              }
            },
          ),
        );
      },
      loading: () => onLoading(true),
      error: (error, stack) {
        LogService.instance.error('Error fetching submission: $error');
        onMessage("Error fetching submission details", isError: true);
      },
    );
  }
}