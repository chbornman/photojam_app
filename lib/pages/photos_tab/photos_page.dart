import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/pages/photos_tab/photoscroll_page.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PhotosPage extends StatefulWidget {
  @override
  _PhotosPageState createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAllSubmissions(); // Fetch fresh data on initialization
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true; // Set disposed flag to prevent further updates
    super.dispose();
  }

  Future<void> _fetchAllSubmissions() async {
    try {
      if (_isDisposed) return;
      setState(() => isLoading = true); // Show loading indicator

      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;
      final authToken = await auth.getToken(); // Get auth token here

      if (userId == null || userId.isEmpty || authToken == null) {
        throw Exception("User ID or auth token is not available.");
      }

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        if (_isDisposed) return; // Stop further processing if disposed

        final date = doc.data['date'] ?? 'Unknown Date';
        final photoUrls =
            List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title')) {
          jamTitle = jamData['title'] ?? 'Untitled';
        }

        List<Uint8List?> photos = [];
        for (var photoUrl in photoUrls) {
          if (_isDisposed) return; // Stop if disposed
          // Pass authToken and use storageApi to fetch authenticated image
          final imageData =
              await _fetchAndCacheImage(photoUrl, authToken, storageApi);
          photos.add(imageData);
        }

        submissions.add({
          'date': date,
          'jamTitle': jamTitle,
          'photos': photos,
        });
      }

      submissions.sort((a, b) => b['date'].compareTo(a['date']));

      if (_isDisposed) return;
      setState(() {
        allSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching submissions: $e');
      if (_isDisposed) return;
      setState(() => isLoading = false);
    }
  }

  Future<Uint8List?> _fetchAndCacheImage(
      String photoUrl, String authToken, StorageAPI storageApi) async {
    final cacheFile = await _getImageCacheFile(photoUrl);

    // Check if the cached image exists
    if (await cacheFile.exists()) {
      print("Loading image from cache: $photoUrl");
      return await cacheFile.readAsBytes();
    }

    // If cache is outdated or unavailable, fetch updated image from the server
    print("Fetching image from network: $photoUrl");

    try {
      // Fetch image using storage API with authToken
      final imageData =
          await storageApi.fetchAuthenticatedImage(photoUrl, authToken);
      if (imageData != null) {
        await cacheFile.writeAsBytes(
            imageData); // Cache the new/updated image data locally
      }
      return imageData;
    } catch (e) {
      print('Error fetching image from network: $e');
      return null;
    }
  }

  // Helper to get a unique cache file path based on the URL
  Future<File> _getImageCacheFile(String photoUrl) async {
    final cacheDir = await getTemporaryDirectory();

    // Generate a unique hash from the full URL to use as the file name
    final sanitizedFileName = sha256.convert(utf8.encode(photoUrl)).toString();

    return File('${cacheDir.path}/$sanitizedFileName.jpg');
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("All Photos"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllSubmissions, // Pull-to-refresh always fetches new data
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
                        color: Colors.white, // Ensure each container also has a white background
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
                                      ? Image.memory(photoData,
                                          width: 100, height: 100)
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