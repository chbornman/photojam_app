import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:provider/provider.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllSubmissions();
  }
  Future<void> _fetchAllSubmissions() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;
      final authToken = await auth.getToken(); // Add a method in AuthAPI to retrieve auth token
      
      if (userId == null || userId.isEmpty || authToken == null) throw Exception("User ID or auth token is not available.");

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photoIds = List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title')) jamTitle = jamData['title'] ?? 'Untitled';

        List<Uint8List?> photos = [];
        for (var photoId in photoIds) {
          final imageData = await storageApi.fetchAuthenticatedImage(photoId, authToken);
          photos.add(imageData);
        }

        submissions.add({
          'date': date,
          'jamTitle': jamTitle,
          'photos': photos,
        });
      }

      submissions.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        allSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching submissions: $e');
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Submissions"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allSubmissions.isEmpty
              ? Center(child: Text("No submissions yet"))
              : ListView.builder(
                  itemCount: allSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = allSubmissions[index];
                    final jamTitle = submission['jamTitle'];
                    final photos = submission['photos'] as List<Uint8List?>;

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jamTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: photos.map((photoData) {
                              return photoData != null
                                  ? Image.memory(photoData, width: 100, height: 100)
                                  : Container(width: 100, height: 100, color: Colors.grey);
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}