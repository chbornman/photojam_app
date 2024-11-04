import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/utilities/markdown_utilities.dart';
import 'package:photojam_app/utilities/standard_button.dart';

class JourneyLessonsPage extends StatefulWidget {
  final String journeyId;
  final String journeyTitle;
  final DatabaseAPI database;
  final StorageAPI storage;

  JourneyLessonsPage({
    required this.journeyId,
    required this.journeyTitle,
    required this.database,
    required this.storage,
  });

  @override
  _JourneyLessonsPageState createState() => _JourneyLessonsPageState();
}

class _JourneyLessonsPageState extends State<JourneyLessonsPage> {
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
      final journey = await widget.database.getJourneyById(widget.journeyId);
      List<String> journeyLessonUrls =
          List<String>.from(journey.data['lessons'] ?? []);

      lessonTitles = await Future.wait(journeyLessonUrls.map((url) async {
        Uint8List? lessonData = await widget.storage.getLessonByURL(url);
        return extractTitleFromMarkdown(lessonData);
      }));

      lessonUrls = journeyLessonUrls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error loading lessons: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addLesson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      String fileName = result.files.single.name;
      Uint8List fileBytes = result.files.single.bytes!;

      try {
        final fileUrl = await widget.storage.uploadLesson(fileBytes, fileName);
        Uint8List? downloadedData =
            await widget.storage.getLessonByURL(fileUrl);
        final lessonTitle = extractTitleFromMarkdown(downloadedData);

        setState(() {
          lessonTitles.add(lessonTitle);
          lessonUrls.add(fileUrl);
          hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Lesson added successfully"),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
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
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete the lesson titled '${lessonTitles[index]}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      setState(() {
        lessonTitles.removeAt(index);
        lessonUrls.removeAt(index);
        hasUnsavedChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lesson deleted successfully"),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _saveChanges() async {
    await widget.database.updateJourneyLessons(widget.journeyId, lessonUrls);
    setState(() => hasUnsavedChanges = false);
    Navigator.of(context).pop(); // Go back to the previous page
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Lessons updated successfully"),
      backgroundColor: Colors.green,
    ));
  }

  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Discard Changes?"),
          content: Text("You have unsaved changes. Are you sure you want to discard them?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Discard"),
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
              icon: Icon(Icons.check),
              onPressed: _saveChanges,
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StandardButton(
            onPressed: _addLesson,
            label: Text("Add New Lesson"),
          ),
        ),
      ),
    );
  }
}