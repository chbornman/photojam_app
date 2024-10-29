import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'dart:io';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  final databaseApi = DatabaseAPI();
  final storageApi = StorageAPI();
  List<Map<String, dynamic>> pastSubmissions = [];
  bool isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _fetchPastSubmissions();
  }

  Future<void> _fetchPastSubmissions() async {
    try {
      // Retrieve past jams that the user participated in
      final response = await databaseApi.getPastJams(); // Implement getPastJams in DatabaseAPI
      
      // Process each jam to get title, date, and images
      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final title = doc.data['title'] ?? 'Unnamed Jam';
        final date = doc.data['date'] ?? 'Unknown Date';
        final photoIds = List<String>.from(doc.data['photoIds'] ?? []);

        // Fetch each photo associated with this jam
        List<File> images = [];
        for (var photoId in photoIds) {
          final filePath = '/path/to/save/$photoId.jpg'; // Define a local path to save images
          await storageApi.downloadPhoto(photoId, filePath);
          images.add(File(filePath));
        }

        submissions.add({'title': title, 'date': date, 'images': images});
      }

      setState(() {
        pastSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching past submissions: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Jam Submissions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : pastSubmissions.isEmpty
                ? Center(
                    child: Text(
                      "No submissions yet",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    itemCount: pastSubmissions.length,
                    itemBuilder: (context, index) {
                      final submission = pastSubmissions[index];
                      final title = submission['title'];
                      final date = submission['date'];
                      final images = submission['images'] as List<File>;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title ($date)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: images
                                  .map((image) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Image.file(
                                            image,
                                            fit: BoxFit.cover,
                                            height: 100,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}