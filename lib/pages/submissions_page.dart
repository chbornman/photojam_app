import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/pages/photoscroll_page.dart';
import 'package:provider/provider.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAllSubmissions();  // Fetch fresh data on initialization
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fetch all submissions metadata and check if images need to be updated
  Future<void> _fetchAllSubmissions() async {
    try {
      setState(() => isLoading = true);  // Show loading indicator

      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;
      final authToken = await auth.getToken();

      if (userId == null || userId.isEmpty || authToken == null) {
        throw Exception("User ID or auth token is not available.");
      }

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photoIds = List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title')) {
          jamTitle = jamData['title'] ?? 'Untitled';
        }

        List<Uint8List?> photos = [];
        for (var photoId in photoIds) {
          final imageData = await _fetchAndCacheImage(photoId, authToken, storageApi);
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

Future<Uint8List?> _fetchAndCacheImage(
    String photoId, String authToken, StorageAPI storageApi) async {
  final cacheFile = await _getImageCacheFile(photoId);

  // Check if the cached image exists
  if (await cacheFile.exists()) {
    final cachedTime = cacheFile.lastModifiedSync();
    final serverLastModified = await storageApi.getFileLastModified(photoId);

    // Check that both dates are non-null and that server time is more recent
    if (serverLastModified != null) {
      if (!serverLastModified.isAfter(cachedTime)) {
        print("Loading image from cache: $photoId");
        return await cacheFile.readAsBytes();
      }
    }
  }

  // If cache is outdated or unavailable, fetch updated image from the server
  print("Fetching image from network: $photoId");
  final imageData = await storageApi.fetchAuthenticatedImage(photoId, authToken);
  if (imageData != null) {
    await cacheFile.writeAsBytes(imageData); // Cache the new/updated image data locally
  }
  return imageData;
}

  // Helper to get the cache file path based on photoId
  Future<File> _getImageCacheFile(String photoId) async {
    final cacheDir = await getTemporaryDirectory();
    final sanitizedPhotoId = Uri.encodeComponent(photoId);
    return File('${cacheDir.path}/$sanitizedPhotoId.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Submissions"),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllSubmissions,  // Pull-to-refresh always fetches new data
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : allSubmissions.isEmpty
                ? ListView(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No submissions yet",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  )
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
                            Text(
                              jamTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: photos.asMap().entries.map((entry) {
                                int photoIndex = entry.key;
                                Uint8List? photoData = entry.value;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoScrollPage(
                                          allSubmissions: allSubmissions,
                                          initialSubmissionIndex: index,
                                          initialPhotoIndex: photoIndex,
                                        ),
                                      ),
                                    );
                                  },
                                  child: photoData != null
                                      ? Image.memory(photoData, width: 100, height: 100)
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey,
                                        ),
                                );
                              }).toList(),
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