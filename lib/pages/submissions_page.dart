import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/pages/photoscroll_page.dart';
import 'package:provider/provider.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;
  bool _dataLoaded = false;
  late Box submissionsBox;
  late Directory cacheDir;
  final Duration cacheTimeout = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    cacheDir = await getTemporaryDirectory();
    await _initializeHiveBox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForDataRefresh();
    }
  }

  Future<void> _initializeHiveBox() async {
    if (!Hive.isBoxOpen('submissionsCache')) {
      submissionsBox = await Hive.openBox('submissionsCache');
    } else {
      submissionsBox = Hive.box('submissionsCache');
    }
    await _loadCachedSubmissions();
  }

  Future<void> _loadCachedSubmissions() async {
    final cachedData = submissionsBox.get('submissions');
    final lastFetchTime = submissionsBox.get('lastFetchTime');

    if (cachedData != null &&
        lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime) < cacheTimeout) {
      setState(() {
        allSubmissions = List<Map<String, dynamic>>.from(
          (cachedData as List).map((item) {
            final photos = List<Uint8List?>.from(
                (item['photos'] as List).map((photo) => photo as Uint8List?));
            return {
              'date': item['date'] as String,
              'jamTitle': item['jamTitle'] as String,
              'photos': photos,
            };
          }),
        );
        isLoading = false;
        _dataLoaded = true;
      });
    }

    if (!_dataLoaded) {
      await _fetchAllSubmissions();
    }
  }

  Future<Uint8List?> _fetchAndCacheImage(
      String photoId, String authToken, StorageAPI storageApi) async {
    // Generate a cache file path using only the photo ID
    final cacheFile = await _getImageCacheFile(photoId);

    if (await cacheFile.exists()) {
      // If the cached file exists, load the image from disk
      print("Loading image from cache: $photoId");
      return await cacheFile.readAsBytes();
    } else {
      // If not cached, fetch the image from the network and save it
      print("Fetching image from network: $photoId");
      final imageData =
          await storageApi.fetchAuthenticatedImage(photoId, authToken);
      if (imageData != null) {
        await cacheFile.writeAsBytes(imageData); // Cache the image data locally
      }
      return imageData;
    }
  }

Future<File> _getImageCacheFile(String photoId) async {
  // Encode photoId to remove any special characters in the path
  final sanitizedPhotoId = Uri.encodeComponent(photoId);
  // Use the verified cache directory path
  return File('${cacheDir.path}/$sanitizedPhotoId.jpg');
}

  Future<void> _fetchAllSubmissions() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;
      final authToken = await auth.getToken();

      if (userId == null || userId.isEmpty || authToken == null)
        throw Exception("User ID or auth token is not available.");

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photoIds =
            List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title'))
          jamTitle = jamData['title'] ?? 'Untitled';

        List<Uint8List?> photos = [];
        for (var photoId in photoIds) {
          final imageData =
              await _fetchAndCacheImage(photoId, authToken, storageApi);
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
        _dataLoaded = true;
      });

      await submissionsBox.put('submissions', submissions);
      await submissionsBox.put('lastFetchTime', DateTime.now());
    } catch (e) {
      print('Error fetching submissions: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkForDataRefresh() async {
    final lastFetchTime = submissionsBox.get('lastFetchTime');
    if (lastFetchTime == null ||
        DateTime.now().difference(lastFetchTime) >= cacheTimeout) {
      setState(() => isLoading = true);
      await _fetchAllSubmissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Submissions"),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllSubmissions,
        child: isLoading
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
                            Text(jamTitle,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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
                                          color: Colors.grey),
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
