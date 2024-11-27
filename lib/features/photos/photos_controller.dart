import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';

class PhotosController extends StateNotifier<AsyncValue<List<Submission>>> {
  final Ref ref;
  final PhotoCacheService _cacheService;

  PhotosController({
    required this.ref,
    required PhotoCacheService cacheService,
  })  : _cacheService = cacheService,
        super(const AsyncValue.loading());

  Future<void> fetchSubmissions() async {
    try {
      state = const AsyncValue.loading();

      // Check authentication
      final authState = ref.read(authStateProvider);
      final user = authState.whenOrNull(
        authenticated: (user) => user,
      );

      if (user == null) {
        throw Exception("User is not authenticated");
      }

      // Get current session
      final session = await ref
          .read(authRepositoryProvider)
          .getCurrentSession();

      // Use watch instead of read for the submissions provider
      final submissionsProvider = ref.watch(userSubmissionsProvider(user.id));
      
      // Handle the AsyncValue state
      final submissions = submissionsProvider.when(
        data: (submissions) => submissions,
        loading: () => <Submission>[],
        error: (error, stack) => throw error,
      );

      final processedSubmissions = 
          await _processSubmissions(submissions, session.$id);

      state = AsyncValue.data(processedSubmissions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error fetching submissions: $error');
    }
  }

  Future<List<Submission>> _processSubmissions(
    List<Submission> submissions,
    String sessionId,
  ) async {
    List<Submission> processedSubmissions = [];

    for (var submission in submissions) {
      try {
        final processedSubmission =
            await _processSubmission(submission, sessionId);
        if (processedSubmission != null) {
          processedSubmissions.add(processedSubmission);
        }
      } catch (e) {
        LogService.instance.error('Error processing submission: $e');
      }
    }

    processedSubmissions.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return processedSubmissions;
  }

  Future<Submission?> _processSubmission(
    Submission submission,
    String sessionId,
  ) async {
    final storageNotifier = ref.read(photoStorageProvider.notifier);
    final photoUrls = submission.photos.take(3).toList();
    
    List<Uint8List?> photos = [];
    for (var photoUrl in photoUrls) {
      final imageData = await _cacheService.getImage(
        photoUrl,
        sessionId,
        () => storageNotifier.downloadFile(photoUrl),
      );
      photos.add(imageData);
    }

    return submission.copyWith(
      photos: photos.whereType<String>().toList(),
    );
  }

  void refresh() {
    fetchSubmissions();
  }
}