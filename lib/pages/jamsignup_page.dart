import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/pages/tabs_page.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class JamSignupPage extends StatefulWidget {
  const JamSignupPage({Key? key}) : super(key: key);

  @override
  _JamSignupPageState createState() => _JamSignupPageState();
}

class _JamSignupPageState extends State<JamSignupPage> {
  String? selectedJamId;
  String? selectedJamName;
  List<DropdownMenuItem<String>> jamEvents = [];
  List<File?> photos = [null, null, null];

  @override
  void initState() {
    super.initState();
    _fetchJamEvents();
  }

  Future<void> _fetchJamEvents() async {
    try {
      final database = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await database.getJams();

      setState(() {
        jamEvents = response.documents
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.$id,
                  child: Text(doc.data['title']),
                ))
            .toList();
      });
    } catch (e) {
      print('Error fetching jam events: $e');
    }
  }

  Future<void> _selectPhoto(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 10 * 1024 * 1024) {
        // Check if file is greater than 10MB
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
              "Selected photo exceeds the 10MB size limit. Please choose a smaller photo."),
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

    // Get the selected Jam name from the database
    final database = Provider.of<DatabaseAPI>(context, listen: false);
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
    if (selectedJamId == null || selectedJamName == null) {
      print("Please select a Jam event");
      return;
    }

    final database = Provider.of<DatabaseAPI>(context, listen: false);
    final storage = Provider.of<StorageAPI>(context, listen: false);
    final auth = Provider.of<AuthAPI>(context, listen: false);

    final userId = await auth.fetchUserId(); // Fetch user ID

    if (userId == null) {
      print("User ID not found. Please log in.");
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
          print("Uploaded photo $i with name $fileName");
        } catch (e) {
          print("Failed to upload photo $i: $e");
        }
      }
    }
// Check for existing submission by user ID for the selected jam
    final existingSubmission =
        await database.getUserSubmissionForJam(selectedJamId!, userId);

    if (existingSubmission != null) {
      // Delete existing photos
      for (String url in existingSubmission.data['photos']) {
        // Extract file ID from URL if needed, then delete
        final fileId = extractFileIdFromUrl(
            url); // Implement a helper to parse file ID from URL
        await storage.deletePhoto(fileId);
      }

      // Update submission with new photos
      await database.updateSubmission(
        existingSubmission.$id,
        photoUrls,
        DateTime.now().toIso8601String(),
      );
      print("Submission updated successfully for Jam: $selectedJamId");
    } else {
      await database.createSubmission(selectedJamId!, photoUrls, userId);
      print("Submission created successfully for Jam: $selectedJamId");
    }
    // Show confirmation dialog and navigate to the home page after confirmation
    _showConfirmationDialog();
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
        return AlertDialog(
          title: Text("Submission Successful"),
          content: Text("Your photos have been submitted successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog

                // Navigate directly to the home page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TabsPage()), // Change to TabsPage or HomePage widget as needed
                  (route) =>
                      false, // This removes all routes until the specified route
                );
              },
              child: Text("OK"),
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
        title: const Text("Jam Signup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Flexible(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                            ? Icon(Icons.photo, size: 50.0, color: Colors.grey)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _submitPhotos,
              child: Text(
                "Submit Photos",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
