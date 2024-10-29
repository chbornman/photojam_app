import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart'; // Import StorageAPI
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JamSignupPage extends StatefulWidget {
  const JamSignupPage({Key? key}) : super(key: key);

  @override
  _JamSignupPageState createState() => _JamSignupPageState();
}

class _JamSignupPageState extends State<JamSignupPage> {
  final database = DatabaseAPI();
  final storageApi = StorageAPI(); // Initialize StorageAPI instance
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
      final response = await database.getJams(); // Use getJams from DatabaseAPI

      setState(() {
        jamEvents = response.documents
            .map((doc) => DropdownMenuItem(
                  value: doc.$id,
                  child: Text(doc.data['name'] ?? 'Unnamed Event'),
                ))
            .toList();
      });
    } catch (e) {
      print('Error fetching events: $e');
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

  Future<void> _submitPhotos() async {
    if (selectedJamId == null) {
      print('Error: No Jam selected.');
      return;
    }

    try {
      for (var photo in photos.where((p) => p != null)) {
        // Upload photo using StorageAPI
        final fileId = await storageApi.uploadPhoto(selectedJamId!, photo!.path);
        if (fileId != null) {
          print('Photo uploaded with file ID: $fileId');
        }
      }
      print('Photos uploaded successfully!');
    } catch (e) {
      print('Error uploading photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up for Jam")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: Text("Select a Jam Event"),
              value: selectedJamId,
              onChanged: (value) => setState(() => selectedJamId = value),
              items: jamEvents,
            ),
            SizedBox(height: 20),
            Text("Upload Photos (1-3)"),
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectPhoto(index),
                    child: Container(
                      height: 100,
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: photos[index] == null
                          ? Icon(Icons.add_a_photo)
                          : Image.file(photos[index]!, fit: BoxFit.cover),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedJamId != null && photos.any((p) => p != null)
                  ? _submitPhotos
                  : null,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}