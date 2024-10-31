import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/constants/constants.dart';

class ContentManagementPage extends StatefulWidget {
  @override
  _ContentManagementPageState createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  late DatabaseAPI database;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    database = Provider.of<DatabaseAPI>(context, listen: false);
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
        return AlertDialog(
          title: Text("Create Journey"),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || startDate == null) {
                  _showMessage("Please enter a title and select a start date.", isError: true);
                  return;
                }
                Map<String, dynamic> journeyData = {
                  "title": titleController.text,
                  "start_date": startDate!.toIso8601String(),
                  "active": isActive,
                };
                Navigator.of(context).pop();
                _executeAction(database.createJourney, journeyData, "Journey created successfully");
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  // Update Journey Dialog
  void _openUpdateJourneyDialog() {
    final TextEditingController journeyIdController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    bool isActive = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Journey"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: journeyIdController,
                decoration: InputDecoration(labelText: "Journey ID"),
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (journeyIdController.text.isEmpty || titleController.text.isEmpty) {
                  _showMessage("Please enter all fields.", isError: true);
                  return;
                }
                Map<String, dynamic> journeyData = {
                  "journeyId": journeyIdController.text,
                  "title": titleController.text,
                  "active": isActive,
                };
                Navigator.of(context).pop();
                _executeAction(database.updateJourney, journeyData, "Journey updated successfully");
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // Delete Journey Dialog
  void _openDeleteJourneyDialog() {
    final TextEditingController journeyIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Journey"),
          content: TextField(
            controller: journeyIdController,
            decoration: InputDecoration(labelText: "Journey ID"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (journeyIdController.text.isEmpty) {
                  _showMessage("Please enter the Journey ID.", isError: true);
                  return;
                }
                Map<String, dynamic> journeyData = {
                  "journeyId": journeyIdController.text,
                };
                Navigator.of(context).pop();
                _executeAction(database.deleteJourney, journeyData, "Journey deleted successfully");
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // Create Jam Dialog
  void _openCreateJamDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Jam"),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: "Jam Title"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  _showMessage("Please enter the Jam title.", isError: true);
                  return;
                }
                Map<String, dynamic> jamData = {
                  "title": titleController.text,
                };
                Navigator.of(context).pop();
                _executeAction(database.createJam, jamData, "Jam created successfully");
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  // Update Jam Dialog
  void _openUpdateJamDialog() {
    final TextEditingController jamIdController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Jam"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jamIdController,
                decoration: InputDecoration(labelText: "Jam ID"),
              ),
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "New Title"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (jamIdController.text.isEmpty || titleController.text.isEmpty) {
                  _showMessage("Please enter all fields.", isError: true);
                  return;
                }
                Map<String, dynamic> jamData = {
                  "jamId": jamIdController.text,
                  "title": titleController.text,
                };
                Navigator.of(context).pop();
                _executeAction(database.updateJam, jamData, "Jam updated successfully");
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // Delete Jam Dialog
  void _openDeleteJamDialog() {
    final TextEditingController jamIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Jam"),
          content: TextField(
            controller: jamIdController,
            decoration: InputDecoration(labelText: "Jam ID"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (jamIdController.text.isEmpty) {
                  _showMessage("Please enter the Jam ID.", isError: true);
                  return;
                }
                Map<String, dynamic> jamData = {
                  "jamId": jamIdController.text,
                };
                Navigator.of(context).pop();
                _executeAction(database.deleteJam, jamData, "Jam deleted successfully");
              },
              child: Text("Delete"),
            ),
          ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              _buildManagementButton("Create Journey", _openCreateJourneyDialog),
              _buildManagementButton("Update Journey", _openUpdateJourneyDialog),
              _buildManagementButton("Delete Journey", _openDeleteJourneyDialog),
              _buildManagementButton("Create Jam", _openCreateJamDialog),
              _buildManagementButton("Update Jam", _openUpdateJamDialog),
              _buildManagementButton("Delete Jam", _openDeleteJamDialog),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            minimumSize: Size(double.infinity, defaultButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultCornerRadius),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}