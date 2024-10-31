import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:image_picker/image_picker.dart';
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
      setState(() {
        photos[index] = File(pickedFile.path);
      });
    }
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

    final username = await auth.getUsername();
    final userId = await auth.fetchUserId(); // Fetch user ID

    if (username == null) {
      print("Username not found. Please log in.");
      return;
    }

    if (userId == null) {
      print("userId not found. Please log in.");
      return;
    }

    List<String> photoUrls = [];

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo != null) {
        String fileName = formatFileName(i, selectedJamName!, username);

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

    final existingSubmission =
        await database.getUserSubmissionForJam(selectedJamId!, username);

    if (existingSubmission != null) {
      await database.updateSubmission(
          existingSubmission.$id, photoUrls, DateTime.now().toIso8601String());
      print("Submission updated successfully for Jam: $selectedJamId");
    } else {
      await database.createSubmission(selectedJamId!, photoUrls, userId);
      print("Submission created successfully for Jam: $selectedJamId");
    }

    // Show confirmation dialog and navigate to the home page after confirmation
    _showConfirmationDialog();
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
      body: Column(
        children: [
          DropdownButton<String>(
            hint: Text("Select Jam Event"),
            value: selectedJamId,
            onChanged: (String? newValue) async {
              await _onJamSelected(newValue);
            },
            items: jamEvents,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return InkWell(
                onTap: () => _selectPhoto(index),
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey),
                    image: photos[index] != null
                        ? DecorationImage(
                            image: FileImage(photos[index]!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photos[index] == null
                      ? Icon(Icons.photo, size: 48.0, color: Colors.grey)
                      : null,
                ),
              );
            }),
          ),
          ElevatedButton(
            onPressed: _submitPhotos,
            child: Text("Submit Photos"),
          ),
        ],
      ),
    );
  }
}
