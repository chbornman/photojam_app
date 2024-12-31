import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';

class PhotosController extends StateNotifier<AsyncValue<List<Submission>>> {
  final Ref ref;

  PhotosController({required this.ref}) : super(const AsyncValue.loading());

  Future<void> fetchSubmissions() async {
    try {
      state = const AsyncValue.loading();

      // Check authentication
      final authState = ref.read(authStateProvider);
      final user = authState.whenOrNull(authenticated: (user) => user);

      if (user == null) {
        throw Exception("User is not authenticated");
      }

      // Use the submissions provider to fetch the user's submissions
      final submissionsProvider = ref.watch(userSubmissionsProvider(user.id));

      // Handle the AsyncValue state from the provider
      final submissions = submissionsProvider.when(
        data: (submissions) => submissions,
        loading: () => <Submission>[],
        error: (error, stack) => throw error,
      );

      // Pass the submissions directly without modifying the photos field
      state = AsyncValue.data(submissions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error fetching submissions: $error');
    }
  }
}
