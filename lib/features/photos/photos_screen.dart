import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';
import 'package:photojam_app/features/photos/photos_content.dart';
import 'package:photojam_app/features/photos/photos_controller.dart';

// Create a provider for PhotoCacheService
final photoCacheServiceProvider = Provider<PhotoCacheService>((ref) {
  return PhotoCacheService();
});

// Create a provider for PhotosController
final photosControllerProvider =
    StateNotifierProvider<PhotosController, AsyncValue<List<Submission>>>(
  (ref) {
    return PhotosController(ref: ref)..fetchSubmissions(); // Initialize fetch
  },
);

class PhotosPage extends ConsumerWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosState = ref.watch(photosControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Submissions"),
      ),
      body: photosState.when(
        data: (submissions) => submissions.isNotEmpty
            ? PhotosContent(submissions: submissions)
            : const Center(
                child: Text(
                  "No submissions yet.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading submissions: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
