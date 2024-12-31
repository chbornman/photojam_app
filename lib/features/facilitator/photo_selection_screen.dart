import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/facilitator/navigation_controls.dart';
import 'package:photojam_app/features/facilitator/photo_grid.dart';
import 'package:share_plus/share_plus.dart';
import './photo_selection_providers.dart';

class PhotoSelectionScreen extends ConsumerStatefulWidget {
  final String jamId;

  const PhotoSelectionScreen({
    super.key,
    required this.jamId,
  });

  @override
  ConsumerState<PhotoSelectionScreen> createState() =>
      _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends ConsumerState<PhotoSelectionScreen> {
  int currentIndex = 0;
  bool isSaving = false;

Future<void> _saveSelections() async {
  final selectedPhotos = ref.read(selectedPhotosProvider(widget.jamId));
  final submissionsAsync =
      ref.read(jamSubmissionsWithImagesProvider(widget.jamId));

  final submissions = submissionsAsync.value;
  if (submissions == null) return;

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
    // Get selected photo IDs
    List<String> selectedPhotoIds = [];
    for (var submissionWithImages in submissions) {
      final selectedIndex =
          selectedPhotos[submissionWithImages.submission.id];
      if (selectedIndex != null) {
        selectedPhotoIds
            .add(submissionWithImages.submission.photos[selectedIndex]);
      }
    }

    // Update jam document with selected photo IDs
    await ref.read(jamsProvider.notifier).updateJam(
          widget.jamId,
          selectedPhotosIds: selectedPhotoIds,
        );

    // Update facilitator to the current user
    final currentUser = ref.read(authStateProvider).user; // Get current user
    final currentUserId = currentUser?.id;

    if (currentUserId != null) {
      await ref.read(jamsProvider.notifier).updateFacilitator(
            widget.jamId,
            currentUserId,
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully saved photo selections'),
          backgroundColor: Colors.green,
        ),
      );

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
        await _sharePhotos(selectedPhotoIds);
      }

      Navigator.of(context).pop();
    }
  } catch (e) {
    LogService.instance.error('Error saving selections: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save selections: $e'),
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

  Future<void> _sharePhotos(List<String> photoIds) async {
    try {
      final storageNotifier = ref.read(photoStorageProvider.notifier);

      // Download and prepare files for sharing
      List<XFile> filesToShare = [];
      for (String photoId in photoIds) {
        final imageData = await storageNotifier.downloadFile(photoId);
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$photoId.jpg';
        final file = File(tempFilePath);
        await file.writeAsBytes(imageData);
        filesToShare.add(XFile(tempFilePath));
      }

      // Open the share menu
      if (mounted) {
        await Share.shareXFiles(
          filesToShare,
          text: 'Check out these photos from PhotoJam!',
        );
      }
    } catch (e) {
      LogService.instance.error('Error sharing photos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync =
        ref.watch(jamSubmissionsWithImagesProvider(widget.jamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Selection'),
        elevation: 0,
      ),
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (submissions) {
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions found'));
          }

          return Column(
            children: [
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
                      submissions[currentIndex]
                          .submission
                          .dateCreation
                          .toString()
                          .split(' ')[0],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PhotoGrid(
                  submission: submissions[currentIndex],
                  onPhotoSelected: (index) => ref
                      .read(selectedPhotosProvider(widget.jamId).notifier)
                      .selectPhoto(
                          submissions[currentIndex].submission.id, index),
                ),
              ),
              NavigationControls(
                currentIndex: currentIndex,
                totalSubmissions: submissions.length,
                selectedPhotosCount:
                    ref.watch(selectedPhotosProvider(widget.jamId)).length,
                isSaving: isSaving,
                onPrevious: currentIndex > 0
                    ? () => setState(() => currentIndex--)
                    : null,
                onNext: currentIndex < submissions.length - 1
                    ? () => setState(() => currentIndex++)
                    : null,
                onSave: _saveSelections,
              ),
            ],
          );
        },
      ),
    );
  }
}
