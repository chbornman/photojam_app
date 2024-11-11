import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/dialogs/delete_journey_dialog.dart';
import 'package:photojam_app/dialogs/update_journey_dialog.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/admin/journeylessons_edit.dart';
import 'package:photojam_app/utilities/standard_button.dart';
import 'package:photojam_app/utilities/standard_card.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/utilities/standard_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:photojam_app/dialogs/create_journey_dialog.dart'; // Import the new dialog

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  _ContentManagementPageState createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  late DatabaseAPI database;
  late StorageAPI storage;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    database = Provider.of<DatabaseAPI>(context, listen: false);
    storage = Provider.of<StorageAPI>(context, listen: false);
  }

  void _showMessage(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _executeAction(
      Future<void> Function(Map<String, dynamic>) action,
      Map<String, dynamic> data,
      String successMessage) async {
    setState(() => isLoading = true);
    try {
      await action(data);
      _showMessage(successMessage);
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _fetchAndOpenUpdateJourneyDialog() async {
    setState(() => isLoading = true);
    try {
      DocumentList journeyList = await database.listJourneys();
      Map<String, String> journeyMap = {
        for (var doc in journeyList.documents) doc.data['title']: doc.$id
      };
      _openUpdateJourneyDialog(journeyMap);
    } catch (e) {
      _showMessage("Error fetching journeys: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

void _fetchAndOpenDeleteJourneyDialog() async {
  setState(() => isLoading = true);
  try {
    DocumentList journeyList = await database.listJourneys();
    Map<String, String> journeyMap = {
      for (var doc in journeyList.documents) doc.data['title']: doc.$id
    };

    showDialog(
      context: context,
      builder: (context) => DeleteJourneyDialog(
        journeyMap: journeyMap,
        onJourneyDeleted: (journeyId) async {
          await _executeAction(
            database.deleteJourney,
            {"journeyId": journeyId},
            "Journey deleted successfully",
          );
        },
      ),
    );
  } catch (e) {
    _showMessage("Error fetching journeys: $e", isError: true);
  } finally {
    setState(() => isLoading = false);
  }
}

  void _fetchAndOpenUpdateJamDialog() async {
    setState(() => isLoading = true);
    try {
      DocumentList jamList = await database.listJams();
      Map<String, String> jamMap = {
        for (var doc in jamList.documents) doc.data['title']: doc.$id
      };
      _openUpdateJamDialog(jamMap);
    } catch (e) {
      _showMessage("Error fetching jams: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _fetchAndOpenDeleteJamDialog() async {
    setState(() => isLoading = true);
    try {
      DocumentList jamList = await database.listJams();
      Map<String, String> jamMap = {
        for (var doc in jamList.documents) doc.data['title']: doc.$id
      };
      _openDeleteJamDialog(jamMap);
    } catch (e) {
      _showMessage("Error fetching jams: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _fetchAndOpenAddLessonDialog(String journeyTitle) async {
    setState(() => isLoading = true);
    try {
      // Get the journey ID for the provided journey title
      DocumentList journeyList = await database.listJourneys();
      final journeyDoc = journeyList.documents.firstWhere(
        (doc) => doc.data['title'] == journeyTitle,
        orElse: () => throw Exception("Journey not found"),
      );

      final journeyId = journeyDoc.$id;
      _openAddLessonDialog(journeyId, journeyTitle);
    } catch (e) {
      _showMessage("Error fetching journey: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openAddLessonDialog(String journeyId, String journeyTitle) {
    Uint8List? selectedFileBytes;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Add Lesson to $journeyTitle",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardButton(
                    label: Text(selectedFileName ?? "Select Lesson File"),
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['md'], // Allow only markdown files
                        withData: true, // Load file data directly into memory
                      );

                      if (result != null && result.files.single.bytes != null) {
                        setState(() {
                          selectedFileName = result.files.single.name;
                          selectedFileBytes = result.files.single.bytes;
                        });
                        LogService.instance.info(
                            "File selected: $selectedFileName - ${selectedFileBytes?.lengthInBytes ?? 0} bytes");
                      } else {
                        LogService.instance
                            .error("No file selected or file has no bytes.");
                      }
                    },
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Upload",
          submitButtonOnPressed: () async {
            if (!mounted) return; // Ensure widget is still mounted
            if (selectedFileBytes == null) {
              _showMessage("Please select a lesson file.", isError: true);
              return;
            }

            try {
              // Step 1: Upload file using the Storage API
              LogService.instance.info(
                  "Uploading file: $selectedFileName with ${selectedFileBytes!.lengthInBytes} bytes");
              final fileUrl = await storage.uploadLesson(
                  selectedFileBytes!, selectedFileName!);

              // Step 2: Add the uploaded file URL to the journey
              LogService.instance.info("File uploaded. URL: $fileUrl");
              await database.addLessonToJourney(journeyId, fileUrl);

              Navigator.of(context).pop();
              _showMessage("Lesson uploaded successfully");
            } catch (e) {
              LogService.instance.error("Error uploading lesson: $e");
              _showMessage("Error uploading lesson: $e", isError: true);
            }
          },
        );
      },
    );
  }

  void _openUpdateJamDialog(Map<String, String> jamMap) {
    String? selectedTitle;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController zoomLinkController = TextEditingController();
    DateTime? jamDate;
    TimeOfDay? jamTime;

    Future<void> loadJamDetails(String jamId) async {
      try {
        final Document selectedJam = await database.getJamById(jamId);
        titleController.text = selectedJam.data['title'] ?? '';
        zoomLinkController.text = selectedJam.data['zoom_link'] ?? '';
        if (selectedJam.data['date'] != null) {
          DateTime jamDateTime = DateTime.parse(selectedJam.data['date']);
          jamDate = jamDateTime;
          jamTime = TimeOfDay.fromDateTime(jamDateTime);
        }
      } catch (e) {
        _showMessage("Error fetching jam details: $e", isError: true);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Update Jam",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTitle,
                    items: jamMap.keys.map((title) {
                      return DropdownMenuItem(
                        value: title,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          selectedTitle = value;
                        });
                        // Clear current field values before loading new data
                        titleController.clear();
                        zoomLinkController.clear();
                        jamDate = null;
                        jamTime = null;
                        await loadJamDetails(jamMap[selectedTitle]!);
                        setState(() {}); // Refresh the form with loaded data
                      }
                    },
                    decoration: InputDecoration(labelText: "Select Jam"),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Jam Title"),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      jamDate == null
                          ? "Select Jam Date"
                          : "Jam Date: ${jamDate?.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: jamDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          jamDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      jamTime == null
                          ? "Select Jam Time"
                          : "Jam Time: ${jamTime?.format(context)}",
                    ),
                    trailing: Icon(Icons.access_time),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: jamTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          jamTime = pickedTime;
                        });
                      }
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: zoomLinkController,
                          decoration: InputDecoration(labelText: "Zoom Link"),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.input),
                        tooltip: "Use default Zoom link",
                        onPressed: () {
                          zoomLinkController.text = zoomLinkUrl;
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Update",
          submitButtonOnPressed: () {
            if (!mounted) return; // Ensure widget is still mounted
            if (titleController.text.isEmpty ||
                jamDate == null ||
                jamTime == null ||
                zoomLinkController.text.isEmpty) {
              _showMessage(
                  "Please enter all required fields, including the Zoom link.",
                  isError: true);
              return;
            }
            DateTime jamDateTime = DateTime(
              jamDate!.year,
              jamDate!.month,
              jamDate!.day,
              jamTime!.hour,
              jamTime!.minute,
            );
            Map<String, dynamic> jamData = {
              "jamId": jamMap[selectedTitle]!,
              "title": titleController.text,
              "date": jamDateTime.toIso8601String(),
              "zoom_link": zoomLinkController.text,
            };
            Navigator.of(context).pop();
            _executeAction(
                database.updateJam, jamData, "Jam updated successfully");
          },
        );
      },
    );
  }

  void _openDeleteJamDialog(Map<String, String> jamMap) {
    String? selectedTitle; // No initial selection
    String? jamTitle;
    DateTime? jamDate;

    Future<void> loadJamDetails(String jamId) async {
      try {
        final Document selectedJam = await database.getJamById(jamId);
        jamTitle = selectedJam.data['title'] ?? '';
        if (selectedJam.data['date'] != null) {
          jamDate = DateTime.parse(selectedJam.data['date']);
        }
      } catch (e) {
        _showMessage("Error fetching jam details: $e", isError: true);
      }
    }

    void showConfirmationDialog() {
      final dateStr =
          jamDate != null ? jamDate!.toLocal().toString().split(' ')[0] : "N/A";
      final timeStr = jamDate != null
          ? TimeOfDay.fromDateTime(jamDate!).format(context)
          : "N/A";

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Confirm Deletion"),
            content: Text(
              "Are you sure you want to delete the following jam?\n\n"
              "Title: $jamTitle\n"
              "Date: $dateStr\n"
              "Time: $timeStr",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel deletion
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close confirmation dialog
                  Navigator.of(context).pop(); // Close delete dialog
                  _executeAction(
                    database.deleteJam,
                    {"jamId": jamMap[selectedTitle]!},
                    "Jam deleted successfully",
                  );
                },
                child: Text("Delete"),
              ),
            ],
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Delete Jam",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTitle,
                    hint: Text("Select Jam"),
                    items: jamMap.keys.map((title) {
                      return DropdownMenuItem(
                        value: title,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          selectedTitle = value;
                          jamTitle = null;
                          jamDate = null;
                        });
                        await loadJamDetails(jamMap[selectedTitle]!);
                        setState(() {}); // Refresh the form with loaded data
                      }
                    },
                    decoration: InputDecoration(labelText: "Select Jam"),
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Delete",
          submitButtonOnPressed: () {
            if (selectedTitle == null) {
              _showMessage("Please select a jam to delete.", isError: true);
              return;
            }
            showConfirmationDialog(); // Show confirmation dialog before deletion
          },
        );
      },
    );
  }

  void _openUpdateJourneyDialog(Map<String, String> journeyMap) {
    String? selectedTitle;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Journey to Update"),
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
                onChanged: (value) async {
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
              onPressed: () async {
                if (selectedTitle != null) {
                  final journeyId = journeyMap[selectedTitle]!;
                  Navigator.of(context).pop(); // Close selection dialog

                  try {
                    final journeyDoc = await database.getJourneyById(journeyId);
                    Map<String, dynamic> initialData = {
                      "title": journeyDoc.data['title'] ?? '',
                      "start_date": journeyDoc.data['start_date'] ?? '',
                      "active": journeyDoc.data['active'] ?? false,
                    };

                    showDialog(
                      context: context,
                      builder: (context) => UpdateJourneyDialog(
                        journeyId: journeyId,
                        initialData: initialData,
                        onJourneyUpdated: (updatedData) async {
                          await _executeAction(
                            database.updateJourney,
                            updatedData,
                            "Journey updated successfully",
                          );
                        },
                      ),
                    );
                  } catch (e) {
                    _showMessage("Error fetching journey details: $e",
                        isError: true);
                  }
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _openCreateJourneyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CreateJourneyDialog(
          onJourneyCreated: (journeyData) async {
            // Call the `createJourney` method on the database API
            await _executeAction(
              database.createJourney,
              journeyData,
              "Journey created successfully",
            );
          },
        );
      },
    );
  }

  void _openCreateJamDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController zoomLinkController = TextEditingController();
    DateTime? jamDate;
    TimeOfDay? jamTime;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Create Jam",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Jam Title"),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      jamDate == null
                          ? "Select Jam Date"
                          : "Jam Date: ${jamDate?.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          jamDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      jamTime == null
                          ? "Select Jam Time"
                          : "Jam Time: ${jamTime?.format(context)}",
                    ),
                    trailing: Icon(Icons.access_time),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          jamTime = pickedTime;
                        });
                      }
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: zoomLinkController,
                          decoration: InputDecoration(labelText: "Zoom Link"),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.input),
                        tooltip: "Use default Zoom link",
                        onPressed: () {
                          zoomLinkController.text = zoomLinkUrl;
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Create",
          submitButtonOnPressed: () {
            if (!mounted) return; // Ensure widget is still mounted
            if (titleController.text.isEmpty ||
                jamDate == null ||
                jamTime == null ||
                zoomLinkController.text.isEmpty) {
              _showMessage(
                  "Please enter all required fields, including the Zoom link.",
                  isError: true);
              return;
            }
            DateTime jamDateTime = DateTime(
              jamDate!.year,
              jamDate!.month,
              jamDate!.day,
              jamTime!.hour,
              jamTime!.minute,
            );
            Map<String, dynamic> jamData = {
              "title": titleController.text,
              "date": jamDateTime.toIso8601String(),
              "zoom_link": zoomLinkController.text,
            };
            Navigator.of(context).pop();
            _executeAction(
                database.createJam, jamData, "Jam created successfully");
          },
        );
      },
    );
  }

  void _fetchAndOpenUpdateJourneyLessonsPage() async {
    setState(() => isLoading = true);
    try {
      // Fetch the list of journeys
      DocumentList journeyList = await database.listJourneys();
      Map<String, String> journeyMap = {
        for (var doc in journeyList.documents) doc.data['title']: doc.$id
      };

      // Show a dialog to select the journey
      _openJourneySelectionDialog(journeyMap);
    } catch (e) {
      _showMessage("Error fetching journeys: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
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
                  _openUpdateJourneyLessonsPage(journeyId, selectedTitle!);
                }
              },
              child: Text("Open"),
            ),
          ],
        );
      },
    );
  }

  void _openUpdateJourneyLessonsPage(String journeyId, String journeyTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JourneyLessonsPage(
          journeyId: journeyId,
          journeyTitle: journeyTitle,
          database: database,
          storage: storage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Content Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 1, // Set to single column for better readability
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 4,
          shrinkWrap: true,
          children: [
            StandardCard(
              icon: Icons.add,
              title: "Create Journey",
              subtitle: "Start a new journey",
              onTap: _openCreateJourneyDialog,
            ),
            StandardCard(
              icon: Icons.edit,
              title: "Update Journey",
              subtitle: "Modify an existing journey",
              onTap: _fetchAndOpenUpdateJourneyDialog,
            ),
            StandardCard(
              icon: Icons.list,
              title: "Update Journey Lessons",
              subtitle: "Reorder, add, or delete lessons in a journey",
              onTap: _fetchAndOpenUpdateJourneyLessonsPage,
            ),
            StandardCard(
              icon: Icons.delete,
              title: "Delete Journey",
              subtitle: "Remove a journey",
              onTap: _fetchAndOpenDeleteJourneyDialog,
            ),
            StandardCard(
              icon: Icons.add,
              title: "Create Jam",
              subtitle: "Start a new jam session",
              onTap: _openCreateJamDialog,
            ),
            StandardCard(
              icon: Icons.edit,
              title: "Update Jam",
              subtitle: "Modify an existing jam session",
              onTap: _fetchAndOpenUpdateJamDialog,
            ),
            StandardCard(
              icon: Icons.delete,
              title: "Delete Jam",
              subtitle: "Remove a jam session",
              onTap: _fetchAndOpenDeleteJamDialog,
            ),
          ],
        ),
      ),
    );
  }
}
