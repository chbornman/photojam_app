import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/facilitator/photo_selection_providers.dart';

class PhotoGrid extends ConsumerWidget {
  final SubmissionWithImages submission;
  final void Function(int) onPhotoSelected;

  const PhotoGrid({
    super.key,
    required this.submission,
    required this.onPhotoSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: submission.images.length,
      itemBuilder: (context, index) {
        final isSelected = ref
            .watch(selectedPhotosProvider(submission.submission.jamId))[submission.submission.id] ==
            index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () => onPhotoSelected(index),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(
                      submission.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
    );
  }
}