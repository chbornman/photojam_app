import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/services/log_service.dart';
import 'package:photojam_app/utilities/standard_submissioncard.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JamDetailsPage extends StatefulWidget {
  final dynamic jam;
  const JamDetailsPage({super.key, required this.jam});

  @override
  _JamDetailsPageState createState() => _JamDetailsPageState();
}

class _JamDetailsPageState extends State<JamDetailsPage>
    with WidgetsBindingObserver {
  bool isLoading = true;
  bool _isDisposed = false;
  List<Uint8List?> photos = [];

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
    super.dispose();
  }

  void _fetchSubmission() async {
    final auth = Provider.of<AuthAPI>(context, listen: false);
    final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
    final storageApi = Provider.of<StorageAPI>(context, listen: false);

    try {
      final userId = auth.userid;
      final authToken = await auth.getToken();

      if (userId == null || userId.isEmpty || authToken == null) {
        throw Exception("User ID or auth token is not available.");
      }

      LogService.instance.info('Fetching submission for user: $userId');
      final submission =
          await databaseApi.getSubmissionByJamAndUser(widget.jam.$id, userId);

      if (!_isDisposed) {
        final photoUrls =
            List<String>.from(submission.data['photos'] ?? []).take(3).toList();

        List<Uint8List?> photos = [];
        for (var photoUrl in photoUrls) {
          if (_isDisposed) return;
          final imageData =
              await _fetchAndCacheImage(photoUrl, authToken, storageApi);
          if (imageData != null) {
            photos.add(imageData);
          } else {
            LogService.instance
                .info('Image data could not be fetched for URL: $photoUrl');
          }
        }

        if (!_isDisposed) {
          setState(() {
            isLoading = false;
            this.photos = photos; // Update the photos list in the state
          });
        }
      }
    } catch (e) {
      LogService.instance.error('Error fetching submission: $e');
      if (!_isDisposed) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _fetchAndCacheImage(
      String photoUrl, String authToken, StorageAPI storageApi) async {
    final cacheFile = await _getImageCacheFile(photoUrl);

    if (await cacheFile.exists()) {
      LogService.instance.info('Loading image from cache for URL: $photoUrl');
      return await cacheFile.readAsBytes();
    }

    try {
      LogService.instance
          .info('Downloading image from network for URL: $photoUrl');
      final imageData =
          await storageApi.fetchAuthenticatedImage(photoUrl, authToken);
      if (imageData != null) {
        await cacheFile.writeAsBytes(imageData);
        LogService.instance.info('Image cached for URL: $photoUrl');
      } else {
        LogService.instance
            .info('No image data received from network for URL: $photoUrl');
      }
      return imageData;
    } catch (e) {
      LogService.instance
          .error('Error fetching image from network for URL $photoUrl: $e');
      return null;
    }
  }

  Future<File> _getImageCacheFile(String photoUrl) async {
    final cacheDir = await getTemporaryDirectory();
    final sanitizedFileName = sha256.convert(utf8.encode(photoUrl)).toString();
    return File('${cacheDir.path}/$sanitizedFileName.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final jamDate = DateTime.parse(widget.jam.data['date']);
    final title = widget.jam.data['title'];
    final zoomLink = widget.jam.data['zoom_link'];
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(jamDate);

    final photoWidgets = [
      Row(
        children: photos.asMap().entries.map((entry) {
          Uint8List? photoData = entry.value;
          return GestureDetector(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: photoData != null
                    ? Image.memory(photoData,
                        width: 100, height: 100, fit: BoxFit.cover)
                    : Container(
                        width: 100,
                        height: 100,
                        color: const Color.fromARGB(255, 106, 35, 35),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date: $formattedDate',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SubmissionCard(
                title: "Your submitted photos", photoWidgets: photoWidgets)
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'joinZoom',
            icon: Icon(Icons.link),
            label: Text("Join Zoom"),
            onPressed: () => _openZoomLink(zoomLink),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'addToCalendar',
            icon: Icon(Icons.calendar_today),
            label: Text("Add to Calendar"),
            onPressed: () =>
                _addToGoogleCalendar(jamDate, title, 'no description'),
          ),
        ],
      ),
    );
  }

  // Function to open the Zoom link
  void _openZoomLink(String zoomLink) async {
    if (await canLaunch(zoomLink)) {
      await launch(zoomLink);
    } else {
      LogService.instance.info('Could not open the Zoom link.');
    }
  }

  void _addToGoogleCalendar(
      DateTime date, String title, String description) async {
    final startDate = date
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];
    final endDate = date
        .add(Duration(hours: 1))
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];

    final googleCalendarUrl = Uri.parse(
      'https://www.google.com/calendar/render?action=TEMPLATE&text=$title&details=$description&dates=$startDate/$endDate',
    );

    if (await canLaunchUrl(googleCalendarUrl)) {
      await launchUrl(googleCalendarUrl);
    } else {
      print('Could not launch Google Calendar');
    }
  }
}
