import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PhotoSelectionScreen extends StatefulWidget {
  final String jamId;

  const PhotoSelectionScreen({
    super.key,
    required this.jamId,
  });

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  int currentIndex = 0;
  bool isLoading = true;
  bool isSaving = false;
  List<SubmissionData> submissions = [];
  Map<String, int> selectedPhotos = {};
  final Map<String, List<Uint8List>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => isLoading = true);

    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final auth = Provider.of<AuthAPI>(context, listen: false);

      final sessionId = await auth.getSessionId();
      if (sessionId == null) {
        throw Exception("No valid session found");
      }

      final submissionDocs =
          await databaseApi.getSubmissionsByJam(widget.jamId);

      for (var doc in submissionDocs.documents) {
        final photoUrls = List<String>.from(doc.data['photos'] ?? []);
        final submissionId = doc.$id;

        // Load images for this submission
        List<Uint8List> images = [];
        for (String url in photoUrls) {
          final imageData =
              await storageApi.fetchAuthenticatedImage(url, sessionId);
          if (imageData != null) {
            images.add(imageData);
          }
        }

        _imageCache[submissionId] = images;

        submissions.add(SubmissionData(
          id: submissionId,
          userId: doc.data['user_id'],
          date: DateTime.parse(doc.data['date']),
          photoUrls: photoUrls,
        ));
      }

      submissions.sort((a, b) => b.date.compareTo(a.date));

      setState(() => isLoading = false);
    } catch (e) {
      LogService.instance.error('Error loading submissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load submissions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSelections() async {
    if (selectedPhotos.length != submissions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select one photo from each submission'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);

      // Create list of selected photo URLs
      List<String> selectedUrls = [];
      for (var submission in submissions) {
        final selectedIndex = selectedPhotos[submission.id];
        if (selectedIndex != null) {
          selectedUrls.add(submission.photoUrls[selectedIndex]);
        }
      }

      // Update jam document with selected photos
      await databaseApi.updateJam({
        'jamId': widget.jamId,
        'selected_photos': selectedUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully saved photo selections'),
            backgroundColor: Colors.green,
          ),
        );

        // Ask the user if they want to save photos to their device
        final saveToDevice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save to Device'),
            content: const Text(
                'Do you want to save the selected photos to your device?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (saveToDevice == true) {
          await _savePhotosToDevice(selectedUrls);
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      LogService.instance.error('Error saving selections: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save selections'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _savePhotosToDevice(List<String> photoUrls) async {
    try {
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final sessionId = await auth.getSessionId();

      if (sessionId == null) {
        throw Exception("No valid session found");
      }

      final directory = await getApplicationDocumentsDirectory();
      final photosDirectory = Directory('${directory.path}/PhotoJam');
      if (!photosDirectory.existsSync()) {
        photosDirectory.createSync(recursive: true);
      }

      for (String url in photoUrls) {
        final imageData =
            await storageApi.fetchAuthenticatedImage(url, sessionId);
        if (imageData != null) {
          final fileName = url.split('/').last;
          final file = File('${photosDirectory.path}/$fileName');
          await file.writeAsBytes(imageData);
        }
      }

      if (mounted) {
        final successMessage = 'Photos saved to ${photosDirectory.path}';

        // Log the successful save path
        LogService.instance.info(successMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final errorMessage = 'Error saving photos to device: $e';

      // Log the error with details
      LogService.instance.error(errorMessage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPhoto(String submissionId, int photoIndex) {
    setState(() {
      selectedPhotos[submissionId] = photoIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (submissions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Selection')),
        body: const Center(
          child: Text('No submissions found'),
        ),
      );
    }

    final currentSubmission = submissions[currentIndex];
    final currentImages = _imageCache[currentSubmission.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Selection'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submission ${currentIndex + 1} of ${submissions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currentSubmission.date.toString().split(' ')[0],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Photos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: currentImages.length,
              itemBuilder: (context, photoIndex) {
                final isSelected =
                    selectedPhotos[currentSubmission.id] == photoIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () => _selectPhoto(currentSubmission.id, photoIndex),
                    child: Stack(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.memory(
                              currentImages[photoIndex],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Selection overlay
                        if (isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                TextButton.icon(
                  onPressed: currentIndex > 0
                      ? () => setState(() => currentIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),

                // Save or Next button
                if (selectedPhotos.length == submissions.length)
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveSelections,
                    icon: Icon(isSaving ? Icons.hourglass_empty : Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save Selections'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: currentIndex < submissions.length - 1
                        ? () => setState(() => currentIndex++)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubmissionData {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> photoUrls;

  SubmissionData({
    required this.id,
    required this.userId,
    required this.date,
    required this.photoUrls,
  });
}
