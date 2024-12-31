import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';
import 'package:photojam_app/features/photos/photoscroll_screen.dart';

class SubmissionItem extends ConsumerWidget {
  final Submission submission;
  final int index;

  const SubmissionItem({
    super.key,
    required this.submission,
    required this.index,
  });

  void _navigateToPhotoScrollPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoScrollPage(
          submission: submission, // Pass the current submission
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the Jam using the jamId from the submission
    final jamAsyncValue = ref.watch(jamByIdProvider(submission.jamId));

    return jamAsyncValue.when(
      data: (jam) {
        if (jam == null) {
          return const Center(
            child: Text('Jam not found'),
          );
        }

        return GestureDetector(
          onTap: () => _navigateToPhotoScrollPage(context),
          child: SubmissionCard(
            title: 'Jam: ${jam.title}', // Display the Jam title
            date: submission.dateCreation.toString(), // Adjust the date format as needed
            photoWidgets: [
              Row(
                children: submission.photos.map((photoId) {
                  return FutureBuilder<Uint8List?>(
                    future: _fetchPhoto(photoId, ref),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      } else {
                        final photoData = snapshot.data;
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
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Error loading jam: $error'),
      ),
    );
  }

  // Function to fetch the photo data from Appwrite storage
  Future<Uint8List?> _fetchPhoto(String fileId, WidgetRef ref) async {
    try {
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      final photoData = await storageNotifier.downloadFile(fileId);
      return photoData;
    } catch (e) {
      debugPrint('Error fetching photo with ID $fileId: $e');
      return null;
    }
  }
}
