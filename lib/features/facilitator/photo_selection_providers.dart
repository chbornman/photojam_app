import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/database/repositories/submission_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Provider for submissions with loaded images for a specific jam
final jamSubmissionsWithImagesProvider = StateNotifierProvider.family<
    JamSubmissionsNotifier,
    AsyncValue<List<SubmissionWithImages>>,
    String>((ref, jamId) {
  final submissionRepository = ref.watch(submissionRepositoryProvider);
  final storageNotifier = ref.watch(photoStorageProvider.notifier);
  return JamSubmissionsNotifier(
    jamId: jamId,
    submissionRepository: submissionRepository,
    storageNotifier: storageNotifier,
  );
});

// Provider for tracking selected photos
final selectedPhotosProvider =
    StateNotifierProvider.family<SelectedPhotosNotifier, Map<String, int>, String>(
        (ref, jamId) {
  return SelectedPhotosNotifier();
});

class SelectedPhotosNotifier extends StateNotifier<Map<String, int>> {
  SelectedPhotosNotifier() : super({});

  void selectPhoto(String submissionId, int photoIndex) {
    state = {...state, submissionId: photoIndex};
  }

  void clearSelections() {
    state = {};
  }
}

class JamSubmissionsNotifier
    extends StateNotifier<AsyncValue<List<SubmissionWithImages>>> {
  final String jamId;
  final SubmissionRepository submissionRepository;
  final StorageNotifier storageNotifier;

  JamSubmissionsNotifier({
    required this.jamId,
    required this.submissionRepository,
    required this.storageNotifier,
  }) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    try {
      state = const AsyncValue.loading();
      LogService.instance.info('Loading submissions for jam: $jamId');

      final submissions = await submissionRepository.getSubmissionsByJam(jamId);
      final submissionsWithImages = <SubmissionWithImages>[];

      for (final submission in submissions) {
        final images = <Uint8List>[];
        for (final photoId in submission.photos) {
          try {
            final imageData = await storageNotifier.downloadFile(photoId);
            images.add(imageData);
          } catch (e) {
            LogService.instance.error('Error loading image $photoId: $e');
          }
        }

        submissionsWithImages.add(
          SubmissionWithImages(
            submission: submission,
            images: images,
          ),
        );
      }

      submissionsWithImages.sort((a, b) => 
        b.submission.dateCreation.compareTo(a.submission.dateCreation)
      );

      LogService.instance.info(
        'Loaded ${submissionsWithImages.length} submissions with images'
      );
      
      state = AsyncValue.data(submissionsWithImages);
    } catch (e, st) {
      LogService.instance.error('Error loading submissions: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

class SubmissionWithImages {
  final Submission submission;
  final List<Uint8List> images;

  SubmissionWithImages({
    required this.submission,
    required this.images,
  });
}