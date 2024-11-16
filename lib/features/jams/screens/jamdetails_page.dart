import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JamDetailsPage extends StatefulWidget {
  final dynamic jam;
  const JamDetailsPage({super.key, required this.jam});

  @override
  _JamDetailsPageState createState() => _JamDetailsPageState();
}

class _JamDetailsPageState extends State<JamDetailsPage> with WidgetsBindingObserver {
  bool isLoading = true;
  bool _isDisposed = false;
  List<Uint8List?> photos = [];
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchSubmission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _imageCache.clear();
    super.dispose();
  }

  Future<void> _fetchSubmission() async {
    if (_isDisposed) return;

    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);

      final userId = auth.userId;
      if (userId == null || !auth.isAuthenticated) {
        throw Exception("User is not authenticated.");
      }

      final sessionId = await auth.getSessionId();
      if (sessionId == null) {
        throw Exception("No valid session found.");
      }

      LogService.instance.info('Fetching submission for user: $userId');
      final submission = await databaseApi.getSubmissionByJamAndUser(
        widget.jam.$id,
        userId,
      );

      if (_isDisposed) return;

      await _processSubmission(submission, sessionId, storageApi);

    } catch (e) {
      LogService.instance.error('Error fetching submission: $e');
      if (!_isDisposed) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load submission');
      }
    }
  }

  Future<void> _processSubmission(
    dynamic submission,
    String sessionId,
    StorageAPI storageApi,
  ) async {
    final photoUrls = List<String>.from(submission.data['photos'] ?? [])
        .take(3)
        .toList();

    List<Uint8List?> newPhotos = [];
    for (var photoUrl in photoUrls) {
      if (_isDisposed) return;
      
      final imageData = await _fetchAndCacheImage(
        photoUrl,
        sessionId,
        storageApi,
      );
      
      if (imageData != null) {
        newPhotos.add(imageData);
      } else {
        LogService.instance.info('Image data could not be fetched for URL: $photoUrl');
      }
    }

    if (!_isDisposed) {
      setState(() {
        isLoading = false;
        photos = newPhotos;
      });
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
      final imageData = await storageApi.fetchAuthenticatedImage(
        photoUrl,
        sessionId,
      );
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _openZoomLink(String zoomLink) async {
    final uri = Uri.parse(zoomLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not open the Zoom link');
      }
    } catch (e) {
      LogService.instance.error('Error launching Zoom link: $e');
      _showErrorSnackBar('Failed to open Zoom link');
    }
  }

  Future<void> _addToGoogleCalendar(
    DateTime date,
    String title,
    String description,
  ) async {
    final startDate = date.toUtc().toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];
    
    final endDate = date.add(const Duration(hours: 1)).toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];

    final uri = Uri.parse(
      'https://www.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&details=${Uri.encodeComponent(description)}'
      '&dates=$startDate/$endDate',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not open Google Calendar');
      }
    } catch (e) {
      LogService.instance.error('Error launching calendar: $e');
      _showErrorSnackBar('Failed to open calendar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jamDate = DateTime.parse(widget.jam.data['date']);
    final title = widget.jam.data['title'];
    final zoomLink = widget.jam.data['zoom_link'];
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(jamDate);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date: $formattedDate',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SubmissionCard(
                title: "Your submitted photos",
                photoWidgets: [
                  Row(
                    children: photos.map((photoData) {
                      return Padding(
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
                                  color: const Color.fromARGB(255, 106, 35, 35),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'joinZoom',
            icon: const Icon(Icons.link),
            label: const Text("Join Zoom"),
            onPressed: () => _openZoomLink(zoomLink),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'addToCalendar',
            icon: const Icon(Icons.calendar_today),
            label: const Text("Add to Calendar"),
            onPressed: () => _addToGoogleCalendar(
              jamDate,
              title,
              'PhotoJam Session',
            ),
          ),
        ],
      ),
    );
  }
}