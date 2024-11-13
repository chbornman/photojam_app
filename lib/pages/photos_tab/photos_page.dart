import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/photos_tab/photoscroll_page.dart';
import 'package:photojam_app/utilities/standard_photocard.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key});

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
    _fetchAllSubmissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _fetchAllSubmissions() async {
    try {
      if (_isDisposed) return;
      setState(() => isLoading = true);

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
        if (_isDisposed) return;

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
          if (_isDisposed) return;
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
      LogService.instance.error('Error fetching submissions: $e');
      if (_isDisposed) return;
      setState(() => isLoading = false);
    }
  }

  Future<Uint8List?> _fetchAndCacheImage(
      String photoUrl, String authToken, StorageAPI storageApi) async {
    final cacheFile = await _getImageCacheFile(photoUrl);

    if (await cacheFile.exists()) {
      return await cacheFile.readAsBytes();
    }

    try {
      final imageData =
          await storageApi.fetchAuthenticatedImage(photoUrl, authToken);
      if (imageData != null) {
        await cacheFile.writeAsBytes(imageData);
      }
      return imageData;
    } catch (e) {
      LogService.instance.error('Error fetching image from network: $e');
      return null;
    }
  }

  Future<File> _getImageCacheFile(String photoUrl) async {
    final cacheDir = await getTemporaryDirectory();
    final sanitizedFileName = sha256.convert(utf8.encode(photoUrl)).toString();
    return File('${cacheDir.path}/$sanitizedFileName.jpg');
  }

  void _navigateToPhotoScrollPage(int index, int photoIndex) {
    if (!isLoading) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _fetchAllSubmissions,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : allSubmissions.isEmpty
                ? Center(
                    child: Text(
                      "No submitted photos yet!",
                      style: TextStyle(fontSize: 18.0, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                : ListView.builder(
                    itemCount: allSubmissions.length,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final submission = allSubmissions[index];
                      final jamTitle = submission['jamTitle'];
                      final date = submission['date'];
                      final photos = submission['photos'] as List<Uint8List?>;

                      // Define how each photo should appear
                      final photoWidgets = [
                        Row(
                          children: photos.asMap().entries.map((entry) {
                            int photoIndex = entry.key;
                            Uint8List? photoData = entry.value;
                            return GestureDetector(
                              onTap: () =>
                                  _navigateToPhotoScrollPage(index, photoIndex),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: photoData != null
                                      ? Image.memory(photoData,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover)
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: const Color.fromARGB(
                                              255, 106, 35, 35),
                                          child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ];

                      // Pass photoWidgets to PhotoCard
                      return PhotoCard(
                        title: jamTitle,
                        date: date,
                        photoWidgets: photoWidgets,
                      );
                    },
                  ),
      ),
    );
  }
}
