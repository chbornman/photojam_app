import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';

class SubmissionItem extends ConsumerWidget {
  final Submission submission;
  final int index;

  const SubmissionItem({
    super.key,
    required this.submission,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoWidgets = submission.photos.take(3).map((photoId) {
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
                        child: const Icon(Icons.image_not_supported, color: Colors.white),
                      ),
              ),
            );
          }
        },
      );
    }).toList();

    return SubmissionCard(
      title: submission.jamId,
      date: submission.dateCreation.toString(), // Format date as needed
      photoWidgets: [
        Row(
          children: photoWidgets,
        ),
      ],
    );
  }

  Future<Uint8List?> _fetchPhoto(String fileId, WidgetRef ref) async {
    try {
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      return await storageNotifier.downloadFile(fileId);
    } catch (e) {
      debugPrint('Error fetching photo with ID $fileId: $e');
      return null;
    }
  }
}
