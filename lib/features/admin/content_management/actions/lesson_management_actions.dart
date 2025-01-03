import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/globals_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/journeys/journey_page.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class LessonManagementActions {
  static void openAddLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add New Lesson"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Select a .zip file containing your markdown file and associated images"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  LogService.instance.info("Starting lesson file selection");

                  // Let user pick a single .zip
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                    withData: true,
                  );

                  if (result != null && result.files.single.bytes != null) {
                    final zipBytes = result.files.single.bytes!;
                    LogService.instance
                        .info("Selected ZIP: ${result.files.single.name}");

                    // Pop the dialog before handling the ZIP
                    Navigator.of(dialogContext).pop();
                    if (!context.mounted) return;

                    // Decode the ZIP using `archive`
                    final archive = ZipDecoder().decodeBytes(zipBytes);

                    // Variables to store the extracted .md and other files
                    String? mdFileName;
                    Uint8List? mdFileBytes;
                    final Map<String, Uint8List> otherFiles = {};

                    // Loop through every file in the ZIP
                    for (final file in archive) {
                      if (file.isFile) {
                        final filename = p.basename(file.name);
                        final data = file.content as List<int>;

                        // Skip hidden files.
                        if (filename.startsWith('.')) {
                          LogService.instance
                              .info('Skipping hidden file: $filename');
                          continue;
                        }

                        // If it’s a .md file, store it separately
                        if (filename.toLowerCase().endsWith('.md')) {
                          mdFileName = filename;
                          mdFileBytes = Uint8List.fromList(data);
                        } else {
                          // Otherwise collect in `otherFiles`
                          otherFiles[filename] = Uint8List.fromList(data);
                        }
                      }
                    }

                    // If we didn’t find any .md file, notify the user
                    if (mdFileName == null || mdFileBytes == null) {
                      onMessage("No .md file found in the ZIP", isError: true);
                      return;
                    }

                    onLoading(true);
                    await _handleCreateLesson(
                      context: context,
                      ref: ref,
                      mdFileName: mdFileName,
                      mdFileBytes: mdFileBytes,
                      otherFiles: otherFiles,
                      onLoading: onLoading,
                      onMessage: onMessage,
                    );
                    onLoading(false);
                  }
                } catch (e) {
                  LogService.instance.error("Error during file selection: $e");
                  if (context.mounted) {
                    onMessage("Error selecting file: $e", isError: true);
                  }
                }
              },
              child: const Text("Select File"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

static Future<void> _handleCreateLesson({
  required BuildContext context,
  required WidgetRef ref,
  required String mdFileName,
  required Uint8List mdFileBytes,
  required Map<String, Uint8List> otherFiles,
  required Function(bool) onLoading,
  required Function(String, {bool isError}) onMessage,
}) async {
  // If no .md file was found
  if (mdFileName.isEmpty || mdFileBytes.isEmpty) {
    onMessage("No .md file found in the ZIP", isError: true);
    return;
  }

  // Get providers early, before async
  final lessonsNotifier = ref.read(lessonsProvider.notifier);

  // Check if a lesson with the same title (mdFileName) already exists
  try {
    // Attempt to read the current list of lessons
    final lessonsAsync = ref.read(lessonsProvider);

    // The lessons provider may be in different states, so handle them safely
    final currentLessons = lessonsAsync.maybeWhen(
      data: (lessons) => lessons,
      orElse: () => <dynamic>[],
    );

    final duplicateFound = currentLessons.any(
      (lesson) => (lesson.title as String).toLowerCase() == mdFileName.toLowerCase(),
    );

    if (duplicateFound) {
      onMessage(
        "A lesson with the name '$mdFileName' already exists. Delete other lesson before adding this one.",
        isError: true,
      );
      return;
    }

    onLoading(true);

    // If no duplicates, proceed with creating a new lesson
    await lessonsNotifier.createLesson(
      mdFileName: mdFileName,
      mdFileBytes: mdFileBytes,
      otherFiles: otherFiles,
    );

    if (!context.mounted) return;
    onMessage("Lesson added successfully");
  } catch (e) {
    LogService.instance.error("Error handling lesson file upload: $e");
    if (!context.mounted) return;
    onMessage("Error handling lesson upload: $e", isError: true);
  } finally {
    if (context.mounted) {
      onLoading(false);
    }
  }
}


  static void openDeleteLessonDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    final lessonsAsync = ref.watch(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        onLoading(false);

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
        onLoading(false);
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
    required Function(String, {bool isError}) onMessage,
  }) async {
    if (selectedLessonId != null) {
      try {
        // Delete the lesson document
        await ref.read(lessonsProvider.notifier).deleteLesson(
              lessonId: selectedLessonId,
            );
        LogService.instance.info("Deleted lesson: $selectedLessonId");

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
