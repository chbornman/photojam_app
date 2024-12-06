// lib/features/content_management/domain/lesson_management_actions.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/globals_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdown_utilities.dart';
import 'package:photojam_app/features/journeys/journey_page.dart';

class LessonManagementActions {
  static void openAddLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Lesson"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select a Markdown (.md) file to upload"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  LogService.instance.info("Starting lesson file selection");

                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['md'],
                    withData: true,
                  );

                  if (result != null && result.files.single.bytes != null) {
                    Navigator.of(context).pop();
                    onLoading(true);

                    final fileName = result.files.single.name;
                    final fileBytes = result.files.single.bytes!;

                    LogService.instance.info("Selected file: $fileName");

                    await _handleLessonFileUpload(
                      ref: ref,
                      fileName: fileName,
                      fileBytes: fileBytes,
                      onMessage: onMessage,
                    );
                  }
                } catch (e) {
                  LogService.instance.error("Error adding lesson: $e");
                  onMessage("Error adding lesson: $e", isError: true);
                } finally {
                  onLoading(false);
                }
              },
              child: const Text("Select File"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleLessonFileUpload({
    required WidgetRef ref,
    required String fileName,
    required Uint8List fileBytes,
    required Function(String, {bool isError}) onMessage,
  }) async {
    try {
      final storageNotifier = ref.read(lessonStorageProvider.notifier);
      final file = await storageNotifier.uploadFile(fileName, fileBytes);
      LogService.instance.info("File uploaded successfully: ${file.id}");

      final content = String.fromCharCodes(fileBytes);
      final title = extractTitleFromMarkdown(fileBytes);

      await ref.read(lessonsProvider.notifier).createLesson(
            title: title,
            content: content,
          );

      onMessage("Lesson added successfully");
    } catch (e) {
      LogService.instance.error("Error handling lesson file upload: $e");
      rethrow;
    }
  }

  static void openUpdateLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!context.mounted) return;

        if (lessons.isEmpty) {
          onMessage("No lessons available", isError: true);
          return;
        }

        _showUpdateLessonDialog(
          context: context,
          ref: ref,
          lessons: lessons,
          onLoading: onLoading,
          onMessage: onMessage,
        );
      },
      loading: () => onLoading(true),
      error: (error, stack) {
        LogService.instance.error("Error fetching lessons: $error");
        onMessage("Error fetching lessons: $error", isError: true);
      },
    );
  }

  static void _showUpdateLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<dynamic> lessons,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    String? selectedLessonId;
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Lesson"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLessonId,
                    hint: const Text("Select Lesson"),
                    items: lessons.map<DropdownMenuItem<String>>((lesson) {
                      // Add explicit type
                      return DropdownMenuItem<String>(
                        value: lesson.id as String,
                        child: Text(lesson.title as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLessonId = value;
                        if (value != null) {
                          final lesson =
                              lessons.firstWhere((l) => l.id == value);
                          titleController.text = lesson.title;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "New Title",
                      hintText: "Enter new title",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _pickAndUploadNewLessonFile(
                      context: context,
                      ref: ref,
                      selectedLessonId: selectedLessonId,
                      titleController: titleController,
                      lessons: lessons,
                      onLoading: onLoading,
                      onMessage: onMessage,
                    ),
                    child: const Text("Select New File"),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => _updateLessonTitleOnly(
              context: context,
              ref: ref,
              selectedLessonId: selectedLessonId,
              titleController: titleController,
              onMessage: onMessage,
            ),
            child: const Text("Update Title Only"),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickAndUploadNewLessonFile({
    required BuildContext context,
    required WidgetRef ref,
    required String? selectedLessonId,
    required TextEditingController titleController,
    required List<dynamic> lessons,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    if (selectedLessonId == null) {
      onMessage("Please select a lesson first", isError: true);
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        onLoading(true);
        Navigator.of(context).pop();

        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final lesson = lessons.firstWhere((l) => l.id == selectedLessonId);

        LogService.instance.info("Updating lesson file: ${lesson.id}");

        final storageNotifier = ref.read(lessonStorageProvider.notifier);

        // Upload new file
        final file = await storageNotifier.uploadFile(fileName, fileBytes);
        LogService.instance.info("New file uploaded: ${file.id}");

        // Delete old file if exists
        try {
          final oldFileId = lesson.content.pathSegments.last;
          await storageNotifier.deleteFile(oldFileId);
          LogService.instance.info("Old file deleted: $oldFileId");
        } catch (e) {
          LogService.instance.error("Error deleting old file: $e");
        }

        // Update lesson document
        final content = String.fromCharCodes(fileBytes);
        await ref.read(lessonsProvider.notifier).updateLesson(
              selectedLessonId,
              title: titleController.text,
              content: content,
            );

        onMessage("Lesson updated successfully");
      }
    } catch (e) {
      LogService.instance.error("Error updating lesson file: $e");
      onMessage("Error updating lesson: $e", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> _updateLessonTitleOnly({
    required BuildContext context,
    required WidgetRef ref,
    required String? selectedLessonId,
    required TextEditingController titleController,
    required Function(String, {bool isError}) onMessage,
  }) async {
    if (selectedLessonId != null) {
      try {
        LogService.instance.info("Updating lesson title: $selectedLessonId");
        await ref.read(lessonsProvider.notifier).updateLesson(
              selectedLessonId,
              title: titleController.text,
            );

        Navigator.of(context).pop();
        onMessage("Lesson title updated successfully");
      } catch (e) {
        LogService.instance.error("Error updating lesson title: $e");
        onMessage("Error updating lesson title: $e", isError: true);
      }
    }
  }

  static void openDeleteLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!context.mounted) return;

        if (lessons.isEmpty) {
          onMessage("No lessons available", isError: true);
          return;
        }

        _showDeleteLessonDialog(
          context: context,
          ref: ref,
          lessons: lessons,
          onMessage: onMessage,
        );
      },
      loading: () => onLoading(true),
      error: (error, stack) {
        LogService.instance.error("Error fetching lessons: $error");
        onMessage("Error fetching lessons: $error", isError: true);
      },
    );
  }

  static void _showDeleteLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<dynamic> lessons,
    required Function(String, {bool isError}) onMessage,
  }) {
    String? selectedLessonId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lesson"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedLessonId,
              hint: const Text("Select Lesson"),
              items: lessons.map<DropdownMenuItem<String>>((lesson) {
                // Add explicit type
                return DropdownMenuItem<String>(
                  value: lesson.id as String,
                  child: Text(lesson.title as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedLessonId = value),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => _handleLessonDeletion(
              context: context,
              ref: ref,
              selectedLessonId: selectedLessonId,
              lessons: lessons,
              onMessage: onMessage,
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleLessonDeletion({
    required BuildContext context,
    required WidgetRef ref,
    required String? selectedLessonId,
    required List<dynamic> lessons,
    required Function(String, {bool isError}) onMessage,
  }) async {
    if (selectedLessonId != null) {
      try {
        final lesson = lessons.firstWhere((l) => l.id == selectedLessonId);
        final fileId = lesson.content.pathSegments.last;

        LogService.instance.info("Deleting lesson and file: $selectedLessonId");

        // Delete the file from storage
        await ref.read(lessonStorageProvider.notifier).deleteFile(fileId);
        LogService.instance.info("Deleted file: $fileId");

        // Delete the lesson document
        await ref
            .read(lessonsProvider.notifier)
            .deleteLessonContent(selectedLessonId);
        LogService.instance.info("Deleted lesson document: $selectedLessonId");

        Navigator.of(context).pop();
        onMessage("Lesson deleted successfully");
      } catch (e) {
        LogService.instance.error("Error deleting lesson: $e");
        onMessage("Error deleting lesson: $e", isError: true);
      }
    }
  }

  static Future<void> fetchAndOpenUpdateJourneyPage({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info("Fetching journeys for lesson update");
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
        data: (journeys) {
          if (!context.mounted) return;

          if (journeys.isEmpty) {
            LogService.instance.info("No journeys found");
            onMessage("No journeys available", isError: true);
            return;
          }

          final journeyMap = {
            for (var journey in journeys) journey.title: journey.id
          };
          LogService.instance.info("Found ${journeys.length} journeys");

          _openJourneySelectionDialog(
            context: context,
            journeyMap: journeyMap,
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error("Error fetching journeys: $error");
          onMessage("Error fetching journeys: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error in journey page navigation: $e");
      onMessage("Error loading journeys", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static void _openJourneySelectionDialog({
    required BuildContext context,
    required Map<String, String> journeyMap,
  }) {
    String? selectedTitle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Journey"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedTitle,
              hint: const Text("Select Journey"),
              isExpanded: true,
              items: journeyMap.keys.map((title) {
                return DropdownMenuItem(
                  value: title,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTitle = value;
                });
              },
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
              if (selectedTitle != null) {
                final journeyId = journeyMap[selectedTitle]!;
                LogService.instance
                    .info("Selected journey: $selectedTitle ($journeyId)");

                Navigator.of(context).pop();
                _navigateToJourneyPage(
                  context: context,
                  journeyId: journeyId,
                  journeyTitle: selectedTitle!,
                );
              }
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  static void _navigateToJourneyPage({
    required BuildContext context,
    required String journeyId,
    required String journeyTitle,
  }) {
    LogService.instance.info("Navigating to journey page for: $journeyTitle");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JourneyPage(
          journeyId: journeyId,
          journeyTitle: journeyTitle,
          isEditMode: true,
        ),
      ),
    );
  }

  static Future<void> setCurrentLesson({
    required WidgetRef ref,
    required String lessonId,
    required Function(String, {bool isError}) onMessage,
  }) async {
    try {
      LogService.instance.info("Setting current lesson: $lessonId");

      // Get the globals repository
      final globalsNotifier = ref.read(globalsProvider.notifier);

      // Get the current_lesson_full global
      final globalsAsync = ref.read(globalByKeyProvider('current_lesson_full'));

      globalsAsync.when(
        data: (global) async {
          if (global != null) {
            // Update existing global
            LogService.instance.info("Updating current_lesson_full global");
            await globalsNotifier.updateGlobal(
              global.id,
              lessonId,
            );
          } else {
            // Create new global if it doesn't exist
            LogService.instance.info("Creating current_lesson_full global");
            await globalsNotifier.createGlobal(
              key: 'current_lesson_full',
              value: lessonId,
              description: 'ID of the current full lesson',
            );
          }
        },
        loading: () => LogService.instance.info("Loading global state..."),
        error: (error, stack) {
          throw Exception("Error accessing globals: $error");
        },
      );

      onMessage("Current lesson updated successfully");
    } catch (e) {
      LogService.instance.error("Error setting current lesson: $e");
      onMessage("Error setting current lesson: $e", isError: true);
    }
  }

  static Future<void> setCurrentLessonSnippet({
    required WidgetRef ref,
    required String lessonId,
    required Function(String, {bool isError}) onMessage,
  }) async {
    try {
      LogService.instance.info("Setting current lesson snippet: $lessonId");

      // Get the globals repository
      final globalsNotifier = ref.read(globalsProvider.notifier);

      // Get the current_lesson_snippet global
      final globalsAsync =
          ref.read(globalByKeyProvider('current_lesson_snippet'));

      globalsAsync.when(
        data: (global) async {
          if (global != null) {
            // Update existing global
            LogService.instance.info("Updating current_lesson_snippet global");
            await globalsNotifier.updateGlobal(
              global.id,
              lessonId,
            );
          } else {
            // Create new global if it doesn't exist
            LogService.instance.info("Creating current_lesson_snippet global");
            await globalsNotifier.createGlobal(
              key: 'current_lesson_snippet',
              value: lessonId,
              description: 'ID of the current lesson snippet',
            );
          }
        },
        loading: () => LogService.instance.info("Loading global state..."),
        error: (error, stack) {
          throw Exception("Error accessing globals: $error");
        },
      );

      onMessage("Current lesson snippet updated successfully");
    } catch (e) {
      LogService.instance.error("Error setting current lesson snippet: $e");
      onMessage("Error setting current lesson snippet: $e", isError: true);
    }
  }

  static void openSetCurrentLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!context.mounted) return;

        if (lessons.isEmpty) {
          onMessage("No lessons available", isError: true);
          return;
        }

        String? selectedLessonId;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Set Current Lesson"),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select the lesson to set as current lesson for members",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLessonId,
                      hint: const Text("Select Lesson"),
                      isExpanded: true,
                      items: lessons.map<DropdownMenuItem<String>>((lesson) {
                        return DropdownMenuItem<String>(
                          value: lesson.id,
                          child: Text(
                            lesson.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedLessonId = value);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedLessonId != null) {
                    Navigator.of(context).pop();
                    onLoading(true);

                    try {
                      LogService.instance.info(
                        "Setting current lesson: $selectedLessonId",
                      );

                      await setCurrentLesson(
                        ref: ref,
                        lessonId: selectedLessonId!,
                        onMessage: onMessage,
                      );
                    } catch (e) {
                      LogService.instance.error(
                        "Error setting current lesson: $e",
                      );
                      onMessage(
                        "Error setting current lesson: $e",
                        isError: true,
                      );
                    } finally {
                      onLoading(false);
                    }
                  } else {
                    onMessage("Please select a lesson", isError: true);
                  }
                },
                child: const Text("Set Current"),
              ),
            ],
          ),
        );
      },
      loading: () => onLoading(true),
      error: (error, stack) {
        LogService.instance.error("Error loading lessons: $error");
        onMessage("Error loading lessons: $error", isError: true);
      },
    );
  }

  static void openSetLessonSnippetDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!context.mounted) return;

        if (lessons.isEmpty) {
          onMessage("No lessons available", isError: true);
          return;
        }

        String? selectedLessonId;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Set Lesson Snippet"),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select the lesson to set as current snippet for non-members",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLessonId,
                      hint: const Text("Select Lesson"),
                      isExpanded: true,
                      items: lessons.map<DropdownMenuItem<String>>((lesson) {
                        return DropdownMenuItem<String>(
                          value: lesson.id,
                          child: Text(
                            lesson.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedLessonId = value);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedLessonId != null) {
                    Navigator.of(context).pop();
                    onLoading(true);

                    try {
                      LogService.instance.info(
                        "Setting lesson snippet: $selectedLessonId",
                      );

                      await setCurrentLessonSnippet(
                        ref: ref,
                        lessonId: selectedLessonId!,
                        onMessage: onMessage,
                      );
                    } catch (e) {
                      LogService.instance.error(
                        "Error setting lesson snippet: $e",
                      );
                      onMessage(
                        "Error setting lesson snippet: $e",
                        isError: true,
                      );
                    } finally {
                      onLoading(false);
                    }
                  } else {
                    onMessage("Please select a lesson", isError: true);
                  }
                },
                child: const Text("Set Snippet"),
              ),
            ],
          ),
        );
      },
      loading: () => onLoading(true),
      error: (error, stack) {
        LogService.instance.error("Error loading lessons: $error");
        onMessage("Error loading lessons: $error", isError: true);
      },
    );
  }
}
