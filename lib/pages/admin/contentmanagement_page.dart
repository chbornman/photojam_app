import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/standard_button.dart';
import 'package:photojam_app/standard_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class ContentManagementPage extends StatefulWidget {
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

  // Create Journey Dialog
  void _openCreateJourneyDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime? startDate;
    bool isActive = false;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Create Journey",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Journey Title"),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      startDate == null
                          ? "Select Start Date"
                          : "Start Date: ${startDate?.toLocal().toString().split(' ')[0]}",
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
                          startDate = pickedDate;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text("Active"),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Create",
          submitButtonOnPressed: () {
            if (titleController.text.isEmpty || startDate == null) {
              _showMessage("Please enter a title and select a start date.",
                  isError: true);
              return;
            }
            Map<String, dynamic> journeyData = {
              "title": titleController.text,
              "start_date": startDate!.toIso8601String(),
              "active": isActive,
            };
            Navigator.of(context).pop();
            _executeAction(database.createJourney, journeyData,
                "Journey created successfully");
          },
        );
      },
    );
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
      _openDeleteJourneyDialog(journeyMap);
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

  void _fetchAndOpenAddLessonDialog() async {
    setState(() => isLoading = true);
    try {
      DocumentList journeyList = await database.listJourneys();
      Map<String, String> journeyMap = {
        for (var doc in journeyList.documents) doc.data['title']: doc.$id
      };
      _openAddLessonDialog(journeyMap);
    } catch (e) {
      _showMessage("Error fetching journeys: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openAddLessonDialog(Map<String, String> journeyMap) {
    String selectedTitle = journeyMap.keys.first;
    Uint8List? selectedFileBytes;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Add Lesson to Journey",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTitle,
                    items: journeyMap.keys.map((title) {
                      return DropdownMenuItem(
                        value: title,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTitle = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Select Journey"),
                  ),
                  SizedBox(height: 16),
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
                        print(
                            "File selected: $selectedFileName - ${selectedFileBytes?.lengthInBytes ?? 0} bytes");
                      } else {
                        print("No file selected or file has no bytes.");
                      }
                    },
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Upload",
          submitButtonOnPressed: () async {
            if (selectedFileBytes == null) {
              _showMessage("Please select a lesson file.", isError: true);
              return;
            }

            try {
              // Step 1: Upload file using the Storage API
              print(
                  "Uploading file: $selectedFileName with ${selectedFileBytes!.lengthInBytes} bytes");
              final fileUrl = await storage.uploadLesson(
                  selectedFileBytes!, selectedFileName!);

              // Step 2: Add the uploaded file URL to the journey
              print("File uploaded. URL: $fileUrl");
              await database.addLessonToJourney(
                  journeyMap[selectedTitle]!, fileUrl);

              Navigator.of(context).pop();
              _showMessage("Lesson uploaded successfully");
            } catch (e) {
              print("Error uploading lesson: $e");
              _showMessage("Error uploading lesson: $e", isError: true);
            }
          },
        );
      },
    );
  }

  void _openUpdateJamDialog(Map<String, String> jamMap) {
    String selectedTitle = jamMap.keys.first;
    final TextEditingController titleController = TextEditingController();

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
                    onChanged: (value) {
                      setState(() {
                        selectedTitle = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Select Jam"),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "New Title"),
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Update",
          submitButtonOnPressed: () {
            if (titleController.text.isEmpty) {
              _showMessage("Please enter all fields.", isError: true);
              return;
            }
            Map<String, dynamic> jamData = {
              "jamId": jamMap[selectedTitle]!,
              "title": titleController.text,
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
    String selectedTitle = jamMap.keys.first;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Delete Jam",
          content: DropdownButtonFormField<String>(
            value: selectedTitle,
            items: jamMap.keys.map((title) {
              return DropdownMenuItem(
                value: title,
                child: Text(title),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTitle = value!;
              });
            },
            decoration: InputDecoration(labelText: "Select Jam"),
          ),
          submitButtonLabel: "Delete",
          submitButtonOnPressed: () {
            Map<String, dynamic> jamData = {
              "jamId": jamMap[selectedTitle]!,
            };
            Navigator.of(context).pop();
            _executeAction(
                database.deleteJam, jamData, "Jam deleted successfully");
          },
        );
      },
    );
  }

  void _openUpdateJourneyDialog(Map<String, String> journeyMap) {
    String selectedTitle = journeyMap.keys.first;
    final TextEditingController titleController = TextEditingController();
    bool isActive = false;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Update Journey",
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTitle,
                    items: journeyMap.keys.map((title) {
                      return DropdownMenuItem(
                        value: title,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTitle = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Select Journey"),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "New Title"),
                  ),
                  SwitchListTile(
                    title: Text("Active"),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Update",
          submitButtonOnPressed: () {
            if (titleController.text.isEmpty) {
              _showMessage("Please enter all fields.", isError: true);
              return;
            }
            Map<String, dynamic> journeyData = {
              "journeyId": journeyMap[selectedTitle]!,
              "title": titleController.text,
              "active": isActive,
            };
            Navigator.of(context).pop();
            _executeAction(database.updateJourney, journeyData,
                "Journey updated successfully");
          },
        );
      },
    );
  }

  void _openDeleteJourneyDialog(Map<String, String> journeyMap) {
    String selectedTitle = journeyMap.keys.first;

    showDialog(
      context: context,
      builder: (context) {
        return StandardDialog(
          title: "Delete Journey",
          content: DropdownButtonFormField<String>(
            value: selectedTitle,
            items: journeyMap.keys.map((title) {
              return DropdownMenuItem(
                value: title,
                child: Text(title),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTitle = value!;
              });
            },
            decoration: InputDecoration(labelText: "Select Journey"),
          ),
          submitButtonLabel: "Delete",
          submitButtonOnPressed: () {
            Map<String, dynamic> journeyData = {
              "journeyId": journeyMap[selectedTitle]!,
            };
            Navigator.of(context).pop();
            _executeAction(database.deleteJourney, journeyData,
                "Journey deleted successfully");
          },
        );
      },
    );
  }

  void _openCreateJamDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController zoomLinkController = TextEditingController();
    DateTime? jamDate;

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
                  TextField(
                    controller: zoomLinkController,
                    decoration: InputDecoration(labelText: "Zoom Link"),
                  ),
                ],
              );
            },
          ),
          submitButtonLabel: "Create",
          submitButtonOnPressed: () {
            if (titleController.text.isEmpty ||
                jamDate == null ||
                zoomLinkController.text.isEmpty) {
              _showMessage(
                  "Please enter all required fields, including the Zoom link.",
                  isError: true);
              return;
            }
            Map<String, dynamic> jamData = {
              "title": titleController.text,
              "date": jamDate!.toIso8601String(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Content Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Set to 2 columns
          crossAxisSpacing: 8.0, // Space between columns
          mainAxisSpacing: 8.0, // Space between rows
          childAspectRatio: 3, // Adjust height of buttons
          shrinkWrap: true, // Makes GridView take only as much space as needed
          children: [
            StandardButton(
              label: Text("Create Journey"),
              onPressed: _openCreateJourneyDialog,
            ),
            StandardButton(
              label: Text("Update Journey"),
              onPressed: _fetchAndOpenUpdateJourneyDialog,
            ),
            StandardButton(
              label: Text("Delete Journey"),
              onPressed: _fetchAndOpenDeleteJourneyDialog,
            ),
            StandardButton(
              label: Text("Create Jam"),
              onPressed: _openCreateJamDialog,
            ),
            StandardButton(
              label: Text("Update Jam"),
              onPressed: _fetchAndOpenUpdateJamDialog,
            ),
            StandardButton(
              label: Text("Delete Jam"),
              onPressed: _fetchAndOpenDeleteJamDialog,
            ),
            StandardButton(
              label: Text("Add Lesson to Journey"),
              onPressed: _fetchAndOpenAddLessonDialog,
            ),
          ],
        ),
      ),
    );
  }
}
