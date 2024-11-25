import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/utils/markdown_utilities.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/core/services/log_service.dart';

class JourneyLessonsEditPage extends ConsumerStatefulWidget {
  final String journeyId;
  final String journeyTitle;

  const JourneyLessonsEditPage({
    super.key,
    required this.journeyId,
    required this.journeyTitle,
  });

  @override
  ConsumerState<JourneyLessonsEditPage> createState() => _JourneyLessonsEditPageState();
}

class _JourneyLessonsEditPageState extends ConsumerState<JourneyLessonsEditPage> { // Change from JourneyPage  List<String> lessonTitles = [];
  List<String> lessonTitles = [];
  List<String> lessonUrls = [];
  bool isLoading = false;
  bool hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => isLoading = true);
    try {
      LogService.instance
          .info("Loading lessons for journey: ${widget.journeyId}");

      // Watch the journey provider
      ref.watch(journeyByIdProvider(widget.journeyId)).when(data: (journey) {
        if (journey == null) {
          LogService.instance.error("Journey not found: ${widget.journeyId}");
          throw Exception("Journey not found");
        }

        List<String> lessonIds = journey.lessonIds;
        List<String> titles = [];

        // Watch lessons provider for each lesson
        for (String lessonId in lessonIds) {
          ref.watch(lessonByIdProvider(lessonId)).whenData((lesson) {
            if (lesson != null) {
              titles.add(lesson.title);
            } else {
              LogService.instance.error("Lesson not found: $lessonId");
            }
          });
        }

        if (mounted) {
          setState(() {
            lessonTitles = titles;
            lessonUrls = lessonIds;
          });
        }
      }, loading: () {
        LogService.instance.info("Loading journey data...");
      }, error: (error, stack) {
        LogService.instance.error("Error loading journey: $error\n$stack");
        throw error;
      });
    } catch (e, stack) {
      LogService.instance.error("Error loading lessons: $e\n$stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error loading lessons: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _addLesson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String fileName = result.files.single.name;
        Uint8List fileBytes = result.files.single.bytes!;

        // Upload to storage
        final storageNotifier = ref.read(lessonStorageProvider.notifier);
        final file = await storageNotifier.uploadFile(fileName, fileBytes);
        LogService.instance.info("Uploaded lesson file: ${file.id}");

        // Create lesson
        final lessonsNotifier = ref.read(lessonsProvider.notifier);
        final content = String.fromCharCodes(fileBytes);
        final title = extractTitleFromMarkdown(fileBytes);

        await lessonsNotifier.createLesson(
          title: title,
          content: content,
          journeyId: widget.journeyId,
        );

        setState(() {
          lessonTitles.add(title);
          lessonUrls.add(file.id);
          hasUnsavedChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lesson added successfully"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      LogService.instance.error("Error adding lesson: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error adding lesson: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _confirmDeleteLesson(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to delete the lesson titled '${lessonTitles[index]}'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      try {
        final lessonId = lessonUrls[index];

        // Delete from storage
        await ref.read(lessonStorageProvider.notifier).deleteFile(lessonId);
        LogService.instance.info("Deleted lesson file: $lessonId");

        setState(() {
          lessonTitles.removeAt(index);
          lessonUrls.removeAt(index);
          hasUnsavedChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lesson deleted successfully"),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        LogService.instance.error("Error deleting lesson: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error deleting lesson: $e"),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      await ref.read(journeysProvider.notifier).updateJourney(
            widget.journeyId,
            lessonIds: lessonUrls,
          );

      setState(() => hasUnsavedChanges = false);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lessons updated successfully"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      LogService.instance.error("Error saving lessons: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error saving lessons: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Discard Changes?"),
          content: const Text(
            "You have unsaved changes. Are you sure you want to discard them?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Discard"),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Manage Lessons for ${widget.journeyTitle}"),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  StandardButton(
                    onPressed: _addLesson,
                    label: const Text("Add New Lesson"),
                  ),
                  Expanded(
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final lessonTitle = lessonTitles.removeAt(oldIndex);
                          final lessonUrl = lessonUrls.removeAt(oldIndex);
                          lessonTitles.insert(newIndex, lessonTitle);
                          lessonUrls.insert(newIndex, lessonUrl);
                          hasUnsavedChanges = true;
                        });
                      },
                      children: List.generate(lessonTitles.length, (index) {
                        return ListTile(
                          key: ValueKey(lessonUrls[index]),
                          title: Text(lessonTitles[index]),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () => _confirmDeleteLesson(index),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
