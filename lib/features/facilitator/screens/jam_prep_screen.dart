import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/facilitator/screens/photoselect_screen.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';

class JamPrepPage extends StatefulWidget {
  const JamPrepPage({super.key});

  @override
  _JamPrepPageState createState() => _JamPrepPageState();
}

class _JamPrepPageState extends State<JamPrepPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;
  bool _isDisposed = false;
  final Map<String, Uint8List?> _imageCache = {};

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
    _imageCache.clear();
    super.dispose();
  }

  Future<void> _fetchAllSubmissions() async {
    if (_isDisposed) return;
    setState(() => isLoading = true);

    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userId;

      if (userId == null || !auth.isAuthenticated) {
        throw Exception("User is not authenticated.");
      }

      final sessionId = await auth.getSessionId();
      if (sessionId == null) {
        throw Exception("No valid session found.");
      }

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        if (_isDisposed) return;

        final submission = await _processSubmission(
          doc,
          sessionId,
          storageApi,
        );
        if (submission != null) {
          submissions.add(submission);
        }
      }

      submissions.sort((a, b) => b['date'].compareTo(a['date']));

      if (!_isDisposed) {
        setState(() {
          allSubmissions = submissions;
          isLoading = false;
        });
      }
    } catch (e) {
      LogService.instance.error('Error fetching submissions: $e');
      if (!_isDisposed) {
        setState(() => isLoading = false);
      }
      _showErrorSnackBar('Failed to load submissions');
    }
  }

  Future<Map<String, dynamic>?> _processSubmission(
    dynamic doc,
    String sessionId,
    StorageAPI storageApi,
  ) async {
    try {
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
        if (_isDisposed) return null;
        final imageData =
            await _fetchAndCacheImage(photoUrl, sessionId, storageApi);
        photos.add(imageData);
      }

      return {
        'date': date,
        'jamTitle': jamTitle,
        'photos': photos,
      };
    } catch (e) {
      LogService.instance.error('Error processing submission: $e');
      return null;
    }
  }

  Future<Uint8List?> _fetchAndCacheImage(
    String photoUrl,
    String sessionId,
    StorageAPI storageApi,
  ) async {
    // Check memory cache first
    if (_imageCache.containsKey(photoUrl)) {
      return _imageCache[photoUrl];
    }

    // Check disk cache
    final cacheFile = await _getImageCacheFile(photoUrl);
    if (await cacheFile.exists()) {
      final imageData = await cacheFile.readAsBytes();
      _imageCache[photoUrl] = imageData;
      return imageData;
    }

    try {
      final imageData =
          await storageApi.fetchAuthenticatedImage(photoUrl, sessionId);
      if (imageData != null) {
        await cacheFile.writeAsBytes(imageData);
        _imageCache[photoUrl] = imageData;
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

  void _navigateToPhotoSelectPage(int index, int photoIndex) {
    if (!isLoading) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoSelectPage(
            allSubmissions: allSubmissions,
            initialSubmissionIndex: index,
            initialPhotoIndex: photoIndex,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
                ? const Center(child: Text('No submissions found'))
                : ListView.builder(
                    itemCount: allSubmissions.length,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final submission = allSubmissions[index];
                      final photos = submission['photos'] as List<Uint8List?>;

                      return SubmissionCard(
                        title: submission['jamTitle'],
                        date: submission['date'],
                        photoWidgets: [
                          Row(
                            children: photos.asMap().entries.map((entry) {
                              int photoIndex = entry.key;
                              Uint8List? photoData = entry.value;
                              return GestureDetector(
                                onTap: () => _navigateToPhotoSelectPage(
                                  index,
                                  photoIndex,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: photoData != null
                                        ? Image.memory(
                                            photoData,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: const Color.fromARGB(
                                                255, 106, 35, 35),
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
