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

  static Future<void> deleteAllLessonsFromStorage({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance
          .info('Initializing lesson files deletion from storage');
      final storageNotifier = ref.read(lessonStorageProvider.notifier);
      final filesAsync = ref.read(lessonStorageProvider);

      await filesAsync.when(
        data: (files) async {
          if (!context.mounted) return;

          if (files.isEmpty) {
            LogService.instance.info('No lesson files found in storage');
            onMessage("No lesson files found in storage", isError: true);
            return;
          }

          final result = await showConfirmationDialog(
            context: context,
            title: "Delete All Lesson Files",
            content:
                "Are you sure you want to delete ${files.length} lesson files from storage? This action cannot be undone.",
          );

          if (result != true) return;

          var successCount = 0;
          var errorCount = 0;

          for (final file in files) {
            try {
              await storageNotifier.deleteFile(file.id);
              LogService.instance.info("Deleted lesson file: ${file.id}");
              successCount++;
            } catch (e) {
              LogService.instance.error("Error deleting file ${file.id}: $e");
              errorCount++;
            }
          }

          onMessage("Deleted $successCount files. Errors: $errorCount");
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error loading files: $error');
          onMessage("Error loading files: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in file deletion process: $e');
      onMessage("Error deleting files: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> deleteSubmissionsAndPhotos({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Initializing submissions and photos deletion');
      final submissionsAsync = ref.read(submissionsProvider);

      submissionsAsync.whenData((submissions) async {
        if (!context.mounted) return;

        if (submissions.isEmpty) {
          LogService.instance.info('No submissions found');
          onMessage("No submissions found", isError: true);
          return;
        }

        final result = await showConfirmationDialog(
          context: context,
          title: "Delete All Submissions",
          content:
              "Are you sure you want to delete ${submissions.length} submissions and their associated photos? This action cannot be undone.",
        );

        if (result != true) return;

        var successCount = 0;
        var errorCount = 0;

        final storageNotifier = ref.read(photoStorageProvider.notifier);

        for (final submission in submissions) {
          try {
            // Delete photos from storage
            for (final photoId in submission.photos) {
              try {
                await storageNotifier.deleteFile(photoId);
                LogService.instance.info("Deleted photo: $photoId");
              } catch (e) {
                LogService.instance.error("Error deleting photo $photoId: $e");
                errorCount++;
              }
            }

            // Delete submission document
            await ref
                .read(submissionsProvider.notifier)
                .deleteSubmission(submission.id);
            LogService.instance.info("Deleted submission: ${submission.id}");
            successCount++;
          } catch (e) {
            LogService.instance.error("Error deleting submission: $e");
            errorCount++;
          }
        }

        onMessage("Deleted $successCount submissions. Errors: $errorCount");
      });
    } catch (e) {
      LogService.instance.error('Error in deletion process: $e');
      onMessage("Error deleting submissions: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> deleteAllPhotosFromStorage({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Initializing photos deletion from storage');
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      final filesAsync = ref.read(photoStorageProvider);

      await filesAsync.when(
        data: (files) async {
          if (!context.mounted) return;

          if (files.isEmpty) {
            LogService.instance.info('No photos found in storage');
            onMessage("No photos found in storage", isError: true);
            return;
          }

          final result = await showConfirmationDialog(
            context: context,
            title: "Delete All Photos",
            content:
                "Are you sure you want to delete ${files.length} photos from storage? This action cannot be undone.",
          );

          if (result != true) return;

          var successCount = 0;
          var errorCount = 0;

          for (final file in files) {
            try {
              await storageNotifier.deleteFile(file.id);
              LogService.instance.info("Deleted photo: ${file.id}");
              successCount++;
            } catch (e) {
              LogService.instance.error("Error deleting photo ${file.id}: $e");
              errorCount++;
            }
          }

          onMessage("Deleted $successCount photos. Errors: $errorCount");
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error loading photos: $error');
          onMessage("Error loading photos: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in photo deletion process: $e');
      onMessage("Error deleting photos: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }
}
