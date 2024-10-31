import 'package:flutter/material.dart';
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
      // Access DatabaseAPI through Provider
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

  Future<void> _uploadPhotos() async {
    try {
      // Access StorageAPI through Provider
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      for (var photo in photos) {
        if (photo != null) {
          final fileBytes = await photo.readAsBytes();
          final fileName = photo.path.split('/').last;
          await storageApi.uploadPhoto(fileBytes, fileName);
        }
      }
      print('Photos uploaded successfully');
    } catch (e) {
      print('Error uploading photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up for a Jam'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedJamId,
              items: jamEvents,
              onChanged: (value) {
                setState(() {
                  selectedJamId = value;
                });
              },
              hint: const Text('Select a Jam Event'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                return GestureDetector(
                  onTap: () => _selectPhoto(index),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: photos[index] != null
                        ? Image.file(photos[index]!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedJamId != null ? _uploadPhotos : null,
              child: const Text('Submit Photos'),
            ),
          ],
        ),
      ),
    );
  }
}