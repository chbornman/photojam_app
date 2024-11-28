import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdown_utilities.dart';
import 'package:photojam_app/dialogs/create_jam_dialog.dart';
import 'package:photojam_app/dialogs/create_journey_dialog.dart';
import 'package:photojam_app/dialogs/delete_jam_dialog.dart';
import 'package:photojam_app/dialogs/delete_journey_dialog.dart';
import 'package:photojam_app/dialogs/update_jam_dialog.dart';
import 'package:photojam_app/dialogs/update_journey_dialog.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';
import 'package:photojam_app/features/admin/danger_action_card.dart';
import 'package:photojam_app/features/journeys/journey_page.dart';

class ContentManagementPage extends ConsumerStatefulWidget {
  const ContentManagementPage({super.key});

  @override
  ConsumerState<ContentManagementPage> createState() =>
      _ContentManagementPageState();
}

class _ContentManagementPageState extends ConsumerState<ContentManagementPage> {
  bool _isLoading = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _fetchAndOpenUpdateJourneyDialog() async {
    setState(() => _isLoading = true);
    try {
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
        data: (journeys) {
          if (!mounted) return;

          final journeyMap = {
            for (var journey in journeys) journey.title: journey.id
          };
          _openUpdateJourneyDialog(journeyMap);
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error fetching journeys: $error");
          _showMessage("Error fetching journeys: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error fetching journeys: $e");
      _showMessage("Error fetching journeys: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndOpenDeleteJourneyDialog() async {
    setState(() => _isLoading = true);
    try {
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
        data: (journeys) {
          if (!mounted) return;

          final journeyMap = {
            for (var journey in journeys) journey.title: journey.id
          };

          showDialog(
            context: context,
            builder: (context) => DeleteJourneyDialog(
              journeyMap: journeyMap,
              onJourneyDeleted: (journeyId) async {
                try {
                  await ref
                      .read(journeysProvider.notifier)
                      .deleteJourney(journeyId);
                  _showMessage("Journey deleted successfully");
                } catch (e) {
                  LogService.instance.error("Error deleting journey: $e");
                  _showMessage("Error deleting journey: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error fetching journeys: $error");
          _showMessage("Error fetching journeys: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error fetching journeys for deletion: $e");
      _showMessage("Error fetching journeys", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndOpenUpdateJamDialog() async {
    setState(() => _isLoading = true);
    try {
      final jamsAsync = ref.read(jamsProvider);

      jamsAsync.when(
        data: (jams) async {
          if (!mounted) return;

          final jamMap = {for (var jam in jams) jam.title: jam.id};

          if (jams.isEmpty) {
            _showMessage("No jams available", isError: true);
            return;
          }

          await showDialog(
            context: context,
            builder: (context) => UpdateJamDialog(
              jamId: jamMap.values.first,
              initialData: {
                'title': jams.first.title,
                'date': jams.first.eventDatetime.toIso8601String(),
                'zoom_link': jams.first.zoomLink,
              },
              onJamUpdated: (updatedData) async {
                try {
                  await ref.read(jamsProvider.notifier).updateJam(
                        jamMap.values.first,
                        title: updatedData['title'],
                        eventDatetime: DateTime.parse(updatedData['date']),
                        zoomLink: updatedData['zoom_link'],
                      );
                  _showMessage("Jam updated successfully");
                } catch (e) {
                  LogService.instance.error("Error updating jam: $e");
                  _showMessage("Error updating jam: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error fetching jams: $error");
          _showMessage("Error fetching jams: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error fetching jams for update: $e");
      _showMessage("Error fetching jams", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndOpenDeleteJamDialog() async {
    setState(() => _isLoading = true);
    try {
      final jamsAsync = ref.read(jamsProvider);

      jamsAsync.when(
        data: (jams) {
          if (!mounted) return;

          final jamMap = {for (var jam in jams) jam.title: jam.id};

          showDialog(
            context: context,
            builder: (context) => DeleteJamDialog(
              jamMap: jamMap,
              onJamDeleted: (jamId) async {
                try {
                  await ref.read(jamsProvider.notifier).deleteJam(jamId);
                  _showMessage("Jam deleted successfully");
                } catch (e) {
                  LogService.instance.error("Error deleting jam: $e");
                  _showMessage("Error deleting jam: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error fetching jams: $error");
          _showMessage("Error fetching jams: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error fetching jams for deletion: $e");
      _showMessage("Error fetching jams", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openUpdateJourneyDialog(Map<String, String> journeyMap) {
    String? selectedTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Journey to Update"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedTitle,
              hint: const Text("Select Journey"),
              items: journeyMap.keys.map((title) {
                return DropdownMenuItem(
                  value: title,
                  child: Text(title),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedTitle = value),
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
                Navigator.of(context).pop();

                ref.read(journeyByIdProvider(journeyId)).when(
                      data: (journey) {
                        if (journey == null) {
                          _showMessage("Journey not found", isError: true);
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (context) => UpdateJourneyDialog(
                            journeyId: journeyId,
                            initialData: {
                              'title': journey.title,
                              'active': journey.isActive,
                            },
                            onJourneyUpdated: (updatedData) async {
                              try {
                                await ref
                                    .read(journeysProvider.notifier)
                                    .updateJourney(
                                      journeyId,
                                      title: updatedData['title'],
                                      isActive: updatedData['active'],
                                    );
                                _showMessage("Journey updated successfully");
                              } catch (e) {
                                LogService.instance
                                    .error("Error updating journey: $e");
                                _showMessage("Error updating journey: $e",
                                    isError: true);
                              }
                            },
                          ),
                        );
                      },
                      loading: () => setState(() => _isLoading = true),
                      error: (error, stack) {
                        LogService.instance
                            .error("Error fetching journey: $error");
                        _showMessage("Error fetching journey details",
                            isError: true);
                      },
                    );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _openCreateJourneyDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateJourneyDialog(
        onJourneyCreated: (journeyData) async {
          try {
            await ref.read(journeysProvider.notifier).createJourney(
                  title: journeyData['title'],
                  isActive: journeyData['active'],
                );
            _showMessage("Journey created successfully");
          } catch (e) {
            LogService.instance.error("Error creating journey: $e");
            _showMessage("Error creating journey: $e", isError: true);
          }
        },
      ),
    );
  }

  void _openCreateJamDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateJamDialog(
        onJamCreated: (jamData) async {
          try {
            // Create a new Jam object with current timestamp and required fields
            final jam = Jam(
              id: 'temp', // This will be replaced by Appwrite
              submissionIds: const [],
              title: jamData['title'],
              eventDatetime: DateTime.parse(jamData['date']),
              zoomLink: jamData['zoom_link'],
              selectedPhotos: const [],
              dateCreated: DateTime.now(),
              dateUpdated: DateTime.now(),
              isActive: true,
            );

            await ref.read(jamsProvider.notifier).createJam(jam);
            _showMessage("Jam created successfully");
          } catch (e) {
            LogService.instance.error("Error creating jam: $e");
            _showMessage("Error creating jam: $e", isError: true);
          }
        },
      ),
    );
  }

  Future<void> _fetchAndOpenUpdateJourneyPage() async {
    setState(() => _isLoading = true);
    try {
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
          data: (journeys) {
            if (!mounted) return;

            final journeyMap = {
              for (var journey in journeys) journey.title: journey.id
            };

            // Show dialog to select the journey
            _openJourneySelectionDialog(journeyMap);
          },
          loading: () => setState(() => _isLoading = true),
          error: (error, stack) {
            LogService.instance.error("Error fetching journeys: $error");
            _showMessage("Error fetching journeys: $error", isError: true);
          });
    } catch (e) {
      LogService.instance
          .error("Error fetching journeys for lesson update: $e");
      _showMessage("Error fetching journeys", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openJourneySelectionDialog(Map<String, String> journeyMap) {
    String? selectedTitle;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Journey"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: selectedTitle,
                hint: Text("Select Journey"),
                items: journeyMap.keys.map((title) {
                  return DropdownMenuItem(
                    value: title,
                    child: Text(title),
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
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (selectedTitle != null) {
                  // Get the journeyId from the selectedTitle
                  final journeyId = journeyMap[selectedTitle]!;
                  Navigator.of(context).pop(); // Close dialog
                  _openUpdateJourneyPage(journeyId, selectedTitle!);
                }
              },
              child: Text("Open"),
            ),
          ],
        );
      },
    );
  }

  void _openUpdateJourneyPage(String journeyId, String journeyTitle) {
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

  Future<void> _deleteSubmissionsAndPhotos() async {
    setState(() => _isLoading = true);
    try {
      final submissionsAsync = ref.read(submissionsProvider);

      await submissionsAsync.whenData((submissions) async {
        if (submissions.isEmpty) {
          _showMessage("No submissions found", isError: true);
          return;
        }

        // Show confirmation dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete All Submissions"),
            content: Text(
                "Are you sure you want to delete ${submissions.length} submissions and their associated photos? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete All"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        );

        if (result != true) return;

        var successCount = 0;
        var errorCount = 0;

        // Delete submissions and their associated photos
        for (final submission in submissions) {
          try {
            // Delete photos from storage
            for (final photoId in submission.photos) {
              try {
                final storageNotifier = ref.read(photoStorageProvider.notifier);
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

        _showMessage("Deleted $successCount submissions. Errors: $errorCount");
      });
    } catch (e) {
      LogService.instance.error("Error in deletion process: $e");
      _showMessage("Error deleting submissions: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLessonsAndFiles() async {
    setState(() => _isLoading = true);
    try {
      final lessonsAsync = ref.read(lessonsProvider);

      await lessonsAsync.whenData((lessons) async {
        if (lessons.isEmpty) {
          _showMessage("No lessons found", isError: true);
          return;
        }

        // Show confirmation dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete All Lessons"),
            content: Text(
                "Are you sure you want to delete ${lessons.length} lessons and their associated files? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete All"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        );

        if (result != true) return;

        var successCount = 0;
        var errorCount = 0;

        // Delete lessons and their associated files
        final storageNotifier = ref.read(lessonStorageProvider.notifier);

        for (final lesson in lessons) {
          try {
            // Extract file ID from content URI
            final fileId = lesson.content.pathSegments.last;

            // Delete lesson file from storage
            try {
              await storageNotifier.deleteFile(fileId);
              LogService.instance.info("Deleted lesson file: $fileId");
            } catch (e) {
              LogService.instance
                  .error("Error deleting lesson file $fileId: $e");
              errorCount++;
            }

            // Delete lesson document
            await ref
                .read(lessonsProvider.notifier)
                .deleteLessonContent(lesson.id);
            LogService.instance.info("Deleted lesson: ${lesson.id}");
            successCount++;
          } catch (e) {
            LogService.instance.error("Error deleting lesson: $e");
            errorCount++;
          }
        }

        _showMessage("Deleted $successCount lessons. Errors: $errorCount");
      });
    } catch (e) {
      LogService.instance.error("Error in deletion process: $e");
      _showMessage("Error deleting lessons: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllPhotosFromStorage() async {
    setState(() => _isLoading = true);
    try {
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      final filesAsync = ref.read(photoStorageProvider);

      filesAsync.when(
        data: (files) async {
          if (files.isEmpty) {
            _showMessage("No photos found in storage", isError: true);
            return;
          }

          // Show confirmation dialog
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete All Photos from Storage"),
              content: Text(
                  "Are you sure you want to delete ${files.length} photos from storage? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete All"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          );

          if (result != true) return;

          var successCount = 0;
          var errorCount = 0;

          // Delete all files from storage
          for (final file in files) {
            try {
              await storageNotifier.deleteFile(file.id);
              LogService.instance
                  .info("Deleted photo from storage: ${file.id}");
              successCount++;
            } catch (e) {
              LogService.instance.error("Error deleting photo ${file.id}: $e");
              errorCount++;
            }
          }

          _showMessage(
              "Deleted $successCount photos from storage. Errors: $errorCount");
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error loading photos: $error");
          _showMessage("Error loading photos: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error in photo deletion process: $e");
      _showMessage("Error deleting photos: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllLessonsFromStorage() async {
    setState(() => _isLoading = true);
    try {
      final storageNotifier = ref.read(lessonStorageProvider.notifier);
      final filesAsync = ref.read(lessonStorageProvider);

      filesAsync.when(
        data: (files) async {
          if (files.isEmpty) {
            _showMessage("No lesson files found in storage", isError: true);
            return;
          }

          // Show confirmation dialog
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete All Lesson Files from Storage"),
              content: Text(
                  "Are you sure you want to delete ${files.length} lesson files from storage? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete All"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          );

          if (result != true) return;

          var successCount = 0;
          var errorCount = 0;

          // Delete all files from storage
          for (final file in files) {
            try {
              await storageNotifier.deleteFile(file.id);
              LogService.instance
                  .info("Deleted lesson file from storage: ${file.id}");
              successCount++;
            } catch (e) {
              LogService.instance
                  .error("Error deleting lesson file ${file.id}: $e");
              errorCount++;
            }
          }

          _showMessage(
              "Deleted $successCount lesson files from storage. Errors: $errorCount");
        },
        loading: () => setState(() => _isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error loading lesson files: $error");
          _showMessage("Error loading lesson files: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error("Error in lesson file deletion process: $e");
      _showMessage("Error deleting lesson files: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddLessonDialog() {
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
                    Navigator.of(context)
                        .pop(); // Close dialog before starting upload

                    setState(() => _isLoading = true);

                    String fileName = result.files.single.name;
                    Uint8List fileBytes = result.files.single.bytes!;

                    LogService.instance.info("Selected file details:");
                    LogService.instance.info("- Original filename: $fileName");
                    LogService.instance
                        .info("- File size: ${fileBytes.length} bytes");

                    // Upload to storage
                    final storageNotifier =
                        ref.read(lessonStorageProvider.notifier);

                    LogService.instance
                        .info("Attempting to upload file to storage:");
                    LogService.instance
                        .info("- Destination filename: $fileName");
                    LogService.instance.info(
                        "- Content type: ${result.files.single.extension}");

                    final file =
                        await storageNotifier.uploadFile(fileName, fileBytes);

                    LogService.instance.info("File upload successful:");
                    LogService.instance.info("- Storage file ID: ${file.id}");
                    LogService.instance
                        .info("- Storage file name: ${file.name}");
                    LogService.instance
                        .info("- Storage file size: ${file.sizeBytes}");
                    LogService.instance
                        .info("- Storage MIME type: ${file.mimeType}");

                    // Create lesson
                    final lessonsNotifier = ref.read(lessonsProvider.notifier);
                    final content = String.fromCharCodes(fileBytes);
                    final title = extractTitleFromMarkdown(fileBytes);

                    LogService.instance.info("Creating lesson record:");
                    LogService.instance.info("- Lesson title: $title");
                    LogService.instance
                        .info("- Content length: ${content.length} characters");

                    await lessonsNotifier.createLesson(
                      title: title,
                      content: content,
                    );

                    if (mounted) {
                      setState(() => _isLoading = false);
                      _showMessage("Lesson added successfully");
                    }
                  }
                } catch (e, stackTrace) {
                  LogService.instance.error("Error adding lesson: $e");
                  LogService.instance.error("Stack trace: $stackTrace");
                  if (mounted) {
                    setState(() => _isLoading = false);
                    _showMessage("Error adding lesson: $e", isError: true);
                  }
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

  void _openUpdateLessonDialog() {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!mounted) return;

        if (lessons.isEmpty) {
          _showMessage("No lessons available", isError: true);
          return;
        }

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
                        items: lessons.map((lesson) {
                          return DropdownMenuItem(
                            value: lesson.id,
                            child: Text(lesson.title),
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
                        onPressed: () async {
                          try {
                            LogService.instance.info(
                                "Starting lesson file selection for update");

                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['md'],
                              withData: true,
                            );

                            if (result != null &&
                                result.files.single.bytes != null) {
                              final fileBytes = result.files.single.bytes!;
                              final fileName = result.files.single.name;

                              LogService.instance
                                  .info("Selected update file: $fileName");

                              if (selectedLessonId != null) {
                                final lesson = lessons.firstWhere(
                                    (l) => l.id == selectedLessonId);

                                // Upload new file
                                final storageNotifier =
                                    ref.read(lessonStorageProvider.notifier);
                                final file = await storageNotifier.uploadFile(
                                    fileName, fileBytes);

                                LogService.instance
                                    .info("Uploaded new file: ${file.id}");

                                // Delete old file
                                final oldFileId =
                                    lesson.content.pathSegments.last;
                                await storageNotifier.deleteFile(oldFileId);

                                LogService.instance
                                    .info("Deleted old file: $oldFileId");

                                // Update lesson document
                                final content = String.fromCharCodes(fileBytes);
                                await ref
                                    .read(lessonsProvider.notifier)
                                    .updateLesson(
                                      selectedLessonId!,
                                      title: titleController.text,
                                      content: content,
                                    );

                                if (mounted) {
                                  Navigator.of(context).pop();
                                  _showMessage("Lesson updated successfully");
                                }
                              }
                            }
                          } catch (e) {
                            LogService.instance
                                .error("Error updating lesson: $e");
                            _showMessage("Error updating lesson: $e",
                                isError: true);
                          }
                        },
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
                onPressed: () async {
                  if (selectedLessonId != null) {
                    try {
                      // Update just the title if no new file was selected
                      await ref.read(lessonsProvider.notifier).updateLesson(
                            selectedLessonId!,
                            title: titleController.text,
                          );

                      if (mounted) {
                        Navigator.of(context).pop();
                        _showMessage("Lesson title updated successfully");
                      }
                    } catch (e) {
                      LogService.instance
                          .error("Error updating lesson title: $e");
                      _showMessage("Error updating lesson title: $e",
                          isError: true);
                    }
                  }
                },
                child: const Text("Update Title Only"),
              ),
            ],
          ),
        );
      },
      loading: () => setState(() => _isLoading = true),
      error: (error, stack) {
        LogService.instance.error("Error fetching lessons: $error");
        _showMessage("Error fetching lessons: $error", isError: true);
      },
    );
  }

  void _openDeleteLessonDialog() {
    final lessonsAsync = ref.read(lessonsProvider);

    lessonsAsync.when(
      data: (lessons) {
        if (!mounted) return;

        if (lessons.isEmpty) {
          _showMessage("No lessons available", isError: true);
          return;
        }

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
                  items: lessons.map((lesson) {
                    return DropdownMenuItem(
                      value: lesson.id,
                      child: Text(lesson.title),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedLessonId = value),
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
                    try {
                      // Get the lesson to access its file ID
                      final lesson =
                          lessons.firstWhere((l) => l.id == selectedLessonId);
                      final fileId = lesson.content.pathSegments.last;

                      // Delete the file from storage
                      await ref
                          .read(lessonStorageProvider.notifier)
                          .deleteFile(fileId);

                      // Delete the lesson document
                      await ref
                          .read(lessonsProvider.notifier)
                          .deleteLessonContent(selectedLessonId!);

                      if (mounted) {
                        Navigator.of(context).pop();
                        _showMessage("Lesson deleted successfully");
                      }
                    } catch (e) {
                      LogService.instance.error("Error deleting lesson: $e");
                      _showMessage("Error deleting lesson: $e", isError: true);
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      },
      loading: () => setState(() => _isLoading = true),
      error: (error, stack) {
        LogService.instance.error("Error fetching lessons: $error");
        _showMessage("Error fetching lessons: $error", isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Management"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CollapsibleSection(
                    title: "Jams",
                    color: AppConstants.photojamPink,
                    children: [
                      StandardCard(
                        icon: Icons.add,
                        title: "Create Jam",
                        onTap: _openCreateJamDialog,
                      ),
                      StandardCard(
                        icon: Icons.edit,
                        title: "Update Jam",
                        onTap: _fetchAndOpenUpdateJamDialog,
                      ),
                      StandardCard(
                        icon: Icons.delete,
                        title: "Delete Jam",
                        onTap: _fetchAndOpenDeleteJamDialog,
                      ),
                    ],
                  ),
                  CollapsibleSection(
                    title: "Journeys",
                    color: AppConstants.photojamDarkPink,
                    children: [
                      StandardCard(
                        icon: Icons.add,
                        title: "Create Journey",
                        onTap: _openCreateJourneyDialog,
                      ),
                      StandardCard(
                        icon: Icons.edit,
                        title: "Update Journey",
                        onTap: _fetchAndOpenUpdateJourneyDialog,
                      ),
                      StandardCard(
                        icon: Icons.delete,
                        title: "Delete Journey",
                        onTap: _fetchAndOpenDeleteJourneyDialog,
                      ),
                    ],
                  ),
                  CollapsibleSection(
                    title: "Lessons",
                    color: AppConstants.photojamDarkGreen,
                    children: [
                      StandardCard(
                        icon: Icons.add,
                        title: "Add Lesson",
                        onTap:
                            _openAddLessonDialog, // You'll need to implement this
                      ),
                      StandardCard(
                        icon: Icons.edit,
                        title: "Update Lesson",
                        onTap: _openUpdateLessonDialog,
                      ),
                      StandardCard(
                        icon: Icons.delete,
                        title: "Delete Lesson",
                        onTap:
                            _openDeleteLessonDialog, // You'll need to implement this
                      ),
                      StandardCard(
                        icon: Icons.list,
                        title: "Update Journey Lessons",
                        onTap: _fetchAndOpenUpdateJourneyPage,
                      ),
                    ],
                  ),
                  CollapsibleSection(
                    title: "Danger Zone",
                    color: AppConstants.photojamPurple,
                    children: [
                      DangerActionCard(
                        icon: Icons.delete_forever,
                        title: "Delete All Lessons and Files",
                        onTap: _deleteLessonsAndFiles,
                      ),
                      DangerActionCard(
                        icon: Icons.folder_delete_outlined,
                        title: "Delete All Lesson Files from Storage",
                        onTap: _deleteAllLessonsFromStorage,
                      ),
                      DangerActionCard(
                        icon: Icons.delete_sweep,
                        title: "Delete All Submissions and Photos",
                        onTap: _deleteSubmissionsAndPhotos,
                      ),
                      DangerActionCard(
                        icon: Icons.photo_library_outlined,
                        title: "Delete All Photos from Storage",
                        onTap: _deleteAllPhotosFromStorage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
