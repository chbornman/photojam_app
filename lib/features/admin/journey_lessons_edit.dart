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
  ConsumerState<JourneyLessonsEditPage> createState() =>
      _JourneyLessonsEditPageState();
}

class _JourneyLessonsEditPageState
    extends ConsumerState<JourneyLessonsEditPage> {
  List<String> lessonTitles = [];
  List<String> lessonUrls = [];
  bool isLoading = true;
  bool hasUnsavedChanges = false;
  bool hasError = false;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      LogService.instance
          .info("Loading lessons for journey: ${widget.journeyId}");

      final journeyAsyncValue =
          ref.watch(journeyByIdProvider(widget.journeyId));

      journeyAsyncValue.when(
        data: (journey) async {
          if (journey == null) {
            throw Exception("Journey not found");
          }

          List<String> titles = [];
          List<String> urls = [];

          // Create a list of Future<void> for each lesson load operation
          final lessonFutures = journey.lessonIds.map((lessonId) async {
            final lessonAsyncValue = ref.watch(lessonByIdProvider(lessonId));

            lessonAsyncValue.when(
              data: (lesson) {
                if (lesson != null) {
                  titles.add(lesson.title);
                  urls.add(lessonId);
                } else {
                  LogService.instance.error("Lesson not found: $lessonId");
                }
              },
              loading: () {}, // Handle loading state if needed
              error: (error, stack) {
                LogService.instance
                    .error("Error loading lesson $lessonId: $error");
              },
            );
          }).toList();

          // Wait for all lessons to load
          await Future.wait(lessonFutures);

          if (mounted) {
            setState(() {
              lessonTitles = titles;
              lessonUrls = urls;
              isLoading = false;
            });
          }
        },
        loading: () => setState(() => isLoading = true),
        error: (error, stack) {
          LogService.instance.error("Error loading journey: $error");
          setState(() {
            hasError = true;
            errorMessage = error.toString();
            isLoading = false;
          });
        },
      );
    } catch (e) {
      LogService.instance.error("Error loading lessons: $e");
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
        _showErrorSnackBar("Error loading lessons: $e");
      }
    }
  }

  Future<void> _addLesson() async {
    try {
      LogService.instance.info("Starting lesson file selection");

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => isLoading = true);

        String fileName = result.files.single.name;
        Uint8List fileBytes = result.files.single.bytes!;

        LogService.instance
            .info("Selected file: $fileName (${fileBytes.length} bytes)");

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

        if (mounted) {
          setState(() {
            lessonTitles.add(title);
            lessonUrls.add(file.id);
            hasUnsavedChanges = true;
            isLoading = false;
          });
          _showSuccessSnackBar("Lesson added successfully");
        }
      }
    } catch (e) {
      LogService.instance.error("Error adding lesson: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar("Error adding lesson: $e");
      }
    }
  }

  Future<void> _confirmDeleteLesson(int index) async {
    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text(
              "Are you sure you want to delete the lesson '${lessonTitles[index]}'?"),
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

    if (shouldDelete == true) {
      await _deleteLesson(index);
    }
  }

  Future<void> _deleteLesson(int index) async {
    try {
      setState(() => isLoading = true);

      final lessonId = lessonUrls[index];
      LogService.instance.info("Deleting lesson: $lessonId");

      // Delete from storage
      await ref.read(lessonStorageProvider.notifier).deleteFile(lessonId);
      LogService.instance.info("Deleted lesson file: $lessonId");

      if (mounted) {
        setState(() {
          lessonTitles.removeAt(index);
          lessonUrls.removeAt(index);
          hasUnsavedChanges = true;
          isLoading = false;
        });
        _showSuccessSnackBar("Lesson deleted successfully");
      }
    } catch (e) {
      LogService.instance.error("Error deleting lesson: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar("Error deleting lesson: $e");
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => isLoading = true);
      LogService.instance
          .info("Saving lesson changes for journey: ${widget.journeyId}");

      await ref.read(journeysProvider.notifier).updateJourney(
            widget.journeyId,
            lessonIds: lessonUrls,
          );

      if (mounted) {
        setState(() {
          hasUnsavedChanges = false;
          isLoading = false;
        });
        _showSuccessSnackBar("Lessons updated successfully");
        Navigator.of(context).pop();
      }
    } catch (e) {
      LogService.instance.error("Error saving lessons: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar("Error saving lessons: $e");
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Manage Lessons for ${widget.journeyTitle}"),
          actions: [
            if (!isLoading && !hasError)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: hasUnsavedChanges ? _saveChanges : null,
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage ?? "An error occurred while loading lessons",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StandardButton(
              onPressed: _loadLessons,
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: StandardButton(
            onPressed: _addLesson,
            label: const Text("Add New Lesson"),
          ),
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteLesson(index),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
