import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';
import 'package:photojam_app/features/photos/screens/photos_content.dart';
import 'package:photojam_app/features/photos/controllers/photos_controller.dart';

// Create a provider for PhotoCacheService
final photoCacheServiceProvider = Provider<PhotoCacheService>((ref) {
  return PhotoCacheService();
});

// Create a provider for PhotosController
final photosControllerProvider = StateNotifierProvider<PhotosController, AsyncValue<List<Submission>>>((ref) {
  return PhotosController(
    ref: ref,
    cacheService: ref.watch(photoCacheServiceProvider),
  )..fetchSubmissions(); // Initialize fetch
});

class PhotosPage extends ConsumerWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosState = ref.watch(photosControllerProvider);

    return photosState.when(
      data: (submissions) => PhotosContent(submissions: submissions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}