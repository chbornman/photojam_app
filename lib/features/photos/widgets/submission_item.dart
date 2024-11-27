// submission_item.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';
import 'package:photojam_app/features/photos/screens/photos_screen.dart';
import 'package:photojam_app/features/photos/screens/photoscroll_screen.dart';

class SubmissionItem extends ConsumerWidget {
  final Submission submission;
  final int index;

  const SubmissionItem({
    super.key,
    required this.submission,
    required this.index,
  });

  void _navigateToPhotoScrollPage(BuildContext context, WidgetRef ref, int photoIndex) {
    // Get all submissions from the provider
    final photosState = ref.read(photosControllerProvider);
    
    photosState.whenOrNull(
      data: (submissions) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoScrollPage(
              submissions: submissions,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoWidgets = [
      Row(
        children: submission.photos.asMap().entries.map((entry) {
          final photoIndex = entry.key;
          final photoData = entry.value;

          return GestureDetector(
            onTap: () => _navigateToPhotoScrollPage(context, ref, photoIndex),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  photoData as Uint8List,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ];

    return SubmissionCard(
      title: submission.jamId,
      date: submission.dateCreation.toString(), // Update this based on your Submission model
      photoWidgets: photoWidgets,
    );
  }
}

// Optional: Add a provider for the selected photo index if needed
final selectedPhotoIndexProvider = StateProvider<int>((ref) => 0);