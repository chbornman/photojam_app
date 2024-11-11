import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/utilities/standard_dialog.dart';
import 'package:photojam_app/pages/mainframe.dart';
import 'package:photojam_app/utilities/standard_button.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class JamSignupPage extends StatefulWidget {
  const JamSignupPage({super.key});

  @override
  _JamSignupPageState createState() => _JamSignupPageState();
}

class _JamSignupPageState extends State<JamSignupPage> {
  String? selectedJamId;
  String? selectedJamName;
  List<DropdownMenuItem<String>> jamEvents = [];
  List<File?> photos = [null, null, null];
  bool isLoading = false;
  final TextEditingController _commentController = TextEditingController();

  late DatabaseAPI database;
  late StorageAPI storage;
  late AuthAPI auth;
  bool hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!hasInitializedDependencies) {
      database = Provider.of<DatabaseAPI>(context, listen: false);
      storage = Provider.of<StorageAPI>(context, listen: false);
      auth = Provider.of<AuthAPI>(context, listen: false);
      hasInitializedDependencies = true;
      _fetchJamEvents();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchJamEvents() async {
    try {
      final response = await database.getJams();
      setState(() {
        jamEvents = response.documents.asMap().entries.map((entry) {
          var doc = entry.value;

          String title = doc.data['title'];
          DateTime dateTime =
              DateTime.parse(doc.data['date']); // Assumes ISO 8601
          String formattedDateTime = DateFormat('MMM dd, yyyy • hh:mm a')
              .format(dateTime); // Example: "Oct 15, 2024 • 02:30 PM"

          return DropdownMenuItem<String>(
            value: doc.$id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  formattedDateTime,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      });
    } catch (e) {
      LogService.instance.error('Error fetching jam events: $e');
    }
  }

  Future<void> _selectPhoto(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 50 * 1024 * 1024) {
        // Check if file is greater than 50MB
        _showSizeWarningDialog();
        return;
      }

      setState(() {
        photos[index] = file;
      });
    }
  }

  Future<void> _showSizeWarningDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("File Size Warning"),
          content: Text(
              "Selected photo exceeds the 50MB size limit. Please choose a smaller photo."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onJamSelected(String? jamId) async {
    if (jamId == null) return;

    setState(() {
      selectedJamId = jamId;
    });

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      database = Provider.of<DatabaseAPI>(context, listen: false);
      storage = Provider.of<StorageAPI>(context, listen: false);
      auth = Provider.of<AuthAPI>(context, listen: false);
    }

    final jamData = await database.getJamById(jamId);
    setState(() {
      selectedJamName = jamData.data['title'] ?? "UnknownJam";
    });
  }

  String formatFileName(int index, String jamName, String username) {
    String date = DateFormat('yyyyMMdd').format(DateTime.now());
    return "${jamName}_${date}_${username}_photo${index + 1}.jpg";
  }

  Future<void> _submitPhotos() async {
    // Step 1: Ensure a Jam is selected
    if (selectedJamId == null || selectedJamName == null) {
      await _showSelectJamWarningDialog();
      return;
    }

    // Step 2: Check if any photos are selected
    bool noPhotosSelected = photos.every((photo) => photo == null);
    if (noPhotosSelected) {
      bool shouldDelete = await _showDeleteWarningDialog();
      if (shouldDelete) {
        await _deleteExistingSubmission();
      }
      return;
    }

    // Step 3: Show loading spinner
    setState(() {
      isLoading = true;
    });

    try {
      final userId = await auth.fetchUserId();
      if (userId == null) {
        LogService.instance.info("User ID not found. Please log in.");
        return;
      }

      List<String> photoUrls = [];
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        if (photo != null) {
          String fileName = formatFileName(i, selectedJamName!, userId);
          try {
            final photoId =
                await storage.uploadPhoto(await photo.readAsBytes(), fileName);
            final photoUrl = await storage.getPhotoUrl(photoId);
            photoUrls.add(photoUrl);
            LogService.instance.info("Uploaded photo $i with name $fileName");
          } catch (e) {
            LogService.instance.error("Failed to upload photo $i: $e");
          }
        }
      }

      final existingSubmission =
          await database.getUserSubmissionForJam(selectedJamId!, userId);
      if (existingSubmission != null) {
        // Delete existing photos
        for (String url in existingSubmission.data['photos']) {
          final fileId = extractFileIdFromUrl(url);
          await storage.deletePhoto(fileId);
          LogService.instance
              .info("Deleted existing photo with file ID: $fileId");
        }

        // Update submission with new photos
        await database.updateSubmission(
          existingSubmission.$id,
          photoUrls,
          DateTime.now().toIso8601String(),
          _commentController.text,
        );
        LogService.instance
            .info("Submission updated successfully for Jam: $selectedJamId");
      } else {
        await database.createSubmission(
            selectedJamId!, photoUrls, userId, _commentController.text);
        LogService.instance
            .error("Submission created successfully for Jam: $selectedJamId");
      }

      // Step 4: Hide loading spinner and show confirmation dialog
      setState(() {
        isLoading = false;
      });
      _showConfirmationDialog();
    } catch (e) {
      LogService.instance.error("Error during photo submission: $e");
      setState(() {
        isLoading = false; // Ensure spinner is hidden if an error occurs
      });
    }
  }

// Helper function to show a dialog if no Jam is selected
  Future<void> _showSelectJamWarningDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select a Jam"),
          content: Text("Please select a Jam event before submitting photos."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

// Helper function to show delete warning dialog if no photos are selected
  Future<bool> _showDeleteWarningDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StandardDialog(
          title: "No Photos Selected",
          content: Text(
              "You have not selected any photos. Submitting will delete your existing submission and its photos. Do you want to proceed?"),
          submitButtonLabel: "Delete Submission",
          submitButtonOnPressed: () {
            if (!mounted) return; // Ensure widget is still mounted
            Navigator.pop(context, true); // Confirm deletion
          },
        );
      },
    ).then((value) => value ?? false);
  }

// Helper function to delete the existing submission and its associated photos
  Future<void> _deleteExistingSubmission() async {
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      database = Provider.of<DatabaseAPI>(context, listen: false);
      storage = Provider.of<StorageAPI>(context, listen: false);
      auth = Provider.of<AuthAPI>(context, listen: false);
    }

    final userId = await auth.fetchUserId();

    if (userId != null) {
      final existingSubmission =
          await database.getUserSubmissionForJam(selectedJamId!, userId);
      if (existingSubmission != null) {
        // Delete associated photos
        for (String url in existingSubmission.data['photos']) {
          final fileId = extractFileIdFromUrl(url);
          await storage.deletePhoto(fileId);
          LogService.instance.info("Deleted photo with file ID: $fileId");
        }

        // Delete the submission itself
        await database.deleteSubmission(existingSubmission.$id);
        LogService.instance
            .info("Existing submission deleted for Jam: $selectedJamId");
      }
    }

    // Navigate back to the home page after deletion
    Navigator.pop(context);
  }

  String extractFileIdFromUrl(String url) {
    // Using RegExp to match the fileId in the URL pattern
    final regex = RegExp(r'/files/([^/]+)/view');
    final match = regex.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!; // Return the fileId
    } else {
      throw Exception('Invalid URL format: Unable to extract file ID');
    }
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StandardDialog(
          title: "Submission Successful",
          content: Text("Your photos have been submitted successfully."),
          submitButtonLabel: "OK",
          submitButtonOnPressed: () async {
            if (!mounted) return; // Ensure widget is still mounted
            Navigator.pop(context); // Close the dialog
            // Navigate to Mainframe with the resolved user role
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => Mainframe(),
              ),
              (route) =>
                  false, // This removes all routes until the specified route
            );
          },
          showCancelButton: false, // Hide the Cancel button
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jam Signup"),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    hint: Text("Select Jam Event"),
                    value: selectedJamId,
                    onChanged: (String? newValue) async {
                      await _onJamSelected(newValue);
                    },
                    items: jamEvents,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Flexible(
                        child: InkWell(
                          onTap: () => _selectPhoto(index),
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: Colors.grey),
                              image: photos[index] != null
                                  ? DecorationImage(
                                      image: FileImage(photos[index]!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: photos[index] == null
                                ? Icon(Icons.photo,
                                    size: 50.0, color: Colors.grey[600])
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Note to facilitator (optional)',
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                StandardButton(
                    label: Text("Submit Photos"),
                    onPressed: () {
                      _submitPhotos();
                    }),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
