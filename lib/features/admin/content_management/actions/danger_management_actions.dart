// lib/features/content_management/domain/danger_management_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/admin/content_management/dialogs/confirmation_dialog.dart';

class DangerManagementActions {
  static Future<void> deleteLessonsAndFiles({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);

    try {
      LogService.instance.info('Initializing lessons deletion process');

      // Get notifier references up front
      final lessonsNotifier = ref.read(lessonsProvider.notifier);

      // Show dialog BEFORE fetching data to avoid mounting issue
      final result = await showConfirmationDialog(
        context: context,
        title: "Delete All Lessons",
        content:
            "Are you sure you want to delete all lessons and their associated files? This action cannot be undone.",
      );

      if (result != true) {
        onLoading(false);
        return;
      }

      // Only fetch data if user confirmed
      final lessons = await lessonsNotifier.getAllLessons();

      if (lessons.isEmpty) {
        LogService.instance.info('No lessons found to delete');
        onMessage("No lessons found", isError: true);
        return;
      }

      var successCount = 0;
      var errorCount = 0;

      for (final lesson in lessons) {
        try {
          await lessonsNotifier.deleteLesson(lessonId: lesson.id);
          LogService.instance.info("Deleted lesson: ${lesson.id}");

          successCount++;
        } catch (e) {
          LogService.instance.error("Error deleting lesson ${lesson.id}: $e");
          errorCount++;
        }
      }

      onMessage("Deleted $successCount lessons. Errors: $errorCount");

      ref.invalidate(lessonStorageProvider);
      ref.invalidate(lessonsProvider);
    } catch (e) {
      LogService.instance.error('Error in deletion process: $e');
      onMessage("Error deleting lessons: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> deleteAllSubmissionsAndPhotos({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);

    try {
      LogService.instance.info('Initializing submissions deletion process');

      // Get notifier reference upfront
      final submissionNotifier = ref.read(submissionRepositoryProvider);

      // Show dialog BEFORE fetching data to avoid mounting issue
      final result = await showConfirmationDialog(
        context: context,
        title: "Delete All Submissions",
        content:
            "Are you sure you want to delete all submissions and their associated photos? This action cannot be undone.",
      );

      if (result != true) {
        onLoading(false);
        return;
      }

      // Fetch submissions only if user confirmed
      final submissions = await submissionNotifier.getAllSubmissions();

      if (submissions.isEmpty) {
        LogService.instance.info('No submissions found to delete');
        onMessage("No submissions found", isError: true);
        return;
      }

      var successCount = 0;
      var errorCount = 0;

      for (final submission in submissions) {
        try {
          await submissionNotifier.deleteSubmission(submission.id);
          LogService.instance.info("Deleted submission: ${submission.id}");

          successCount++;
        } catch (e) {
          LogService.instance
              .error("Error deleting submission ${submission.id}: $e");
          errorCount++;
        }
      }

      onMessage("Deleted $successCount submissions. Errors: $errorCount");

      // Invalidate providers to refresh state
      ref.invalidate(submissionRepositoryProvider);
    } catch (e) {
      LogService.instance.error('Error in submissions deletion process: $e');
      onMessage("Error deleting submissions: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }
}
