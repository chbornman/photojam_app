import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class JamSignupPage extends StatefulWidget {
  const JamSignupPage({Key? key}) : super(key: key);

  @override
  _JamSignupPageState createState() => _JamSignupPageState();
}

class _JamSignupPageState extends State<JamSignupPage> {
  String? selectedJamId;
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
  }

Future<void> _submitPhotos() async {
  if (selectedJamId == null) {
    print("Please select a Jam event");
    return;
  }

  final database = Provider.of<DatabaseAPI>(context, listen: false);
  final storage = Provider.of<StorageAPI>(context, listen: false);
  final userId = Provider.of<AuthAPI>(context, listen: false).userid;
  
  List<String> photoUrls = [];  // Stores URLs instead of IDs

  // Upload each photo and get their URLs
  for (var photo in photos) {
    if (photo != null) {
      final photoId = await storage.uploadPhoto(await photo.readAsBytes(), "submission_photo");
      final photoUrl = await storage.getPhotoUrl(photoId);  // Convert to full URL
      photoUrls.add(photoUrl);
    }
  }

  final existingSubmission = await database.getUserSubmissionForJam(selectedJamId!, userId!);

  if (existingSubmission != null) {
    await database.updateSubmission(existingSubmission.$id, photoUrls, DateTime.now().toIso8601String());
    print("Submission updated successfully for Jam: $selectedJamId");
  } else {
    await database.createSubmission(selectedJamId!, photoUrls, userId);
    print("Submission created successfully for Jam: $selectedJamId");
  }
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
                  width: 100.0,  // Increase container size
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
                      : null, // Show icon if no photo selected
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