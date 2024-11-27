import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/repositories/submission_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Base repository provider
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  return SubmissionRepository(dbRepository);
});

// Main state notifier provider for all submissions
final submissionsProvider = StateNotifierProvider<SubmissionsNotifier, AsyncValue<List<Submission>>>((ref) {
  final repository = ref.watch(submissionRepositoryProvider);
  return SubmissionsNotifier(repository);
});

// Provider for submissions by jam
final jamSubmissionsProvider = Provider.family<AsyncValue<List<Submission>>, String>((ref, jamId) {
  return ref.watch(submissionsProvider).whenData(
    (submissions) => submissions
        .where((submission) => submission.jamId == jamId)
        .toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation)),
  );
});

// Provider for user submissions
final userSubmissionsProvider = Provider.family<AsyncValue<List<Submission>>, String>((ref, userId) {
  return ref.watch(submissionsProvider).whenData(
    (submissions) => submissions
        .where((submission) => submission.userId == userId)
        .toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation)),
  );
});

// Provider for user's submission to a specific jam
final userJamSubmissionProvider = Provider.family<AsyncValue<Submission?>, ({String userId, String jamId})>((ref, params) {
  return ref.watch(submissionsProvider).whenData(
    (submissions) => submissions.firstWhereOrNull(
      (submission) => submission.userId == params.userId && submission.jamId == params.jamId,
    ),
  );
});

// Provider for submissions within a date range
final dateRangeSubmissionsProvider = Provider.family<AsyncValue<List<Submission>>, ({DateTime start, DateTime end, String? userId, String? jamId})>((ref, params) {
  return ref.watch(submissionsProvider).whenData(
    (submissions) => submissions
        .where((submission) =>
            submission.dateCreation.isAfter(params.start) &&
            submission.dateCreation.isBefore(params.end) &&
            (params.userId == null || submission.userId == params.userId) &&
            (params.jamId == null || submission.jamId == params.jamId))
        .toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation)),
  );
});

// Provider for a specific submission by ID
final submissionByIdProvider = Provider.family<AsyncValue<Submission?>, String>((ref, submissionId) {
  return ref.watch(submissionsProvider).whenData(
    (submissions) => submissions.firstWhereOrNull((s) => s.id == submissionId),
  );
});

class SubmissionsNotifier extends StateNotifier<AsyncValue<List<Submission>>> {
  final SubmissionRepository _repository;

  SubmissionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    try {
      state = const AsyncValue.loading();
      // Since there's no getAllSubmissions in repository, we'll manage the state
      // through individual operations
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error loading submissions: $error');
    }
  }

  Future<Submission> createSubmission({
    required String userId,
    required String jamId,
    required List<String> photos,
    String? comment,
  }) async {
    try {
      final submission = await _repository.createSubmission(
        userId: userId,
        jamId: jamId,
        photos: photos,
        comment: comment,
      );
      
      state = state.whenData((submissions) => [
        ...submissions,
        submission,
      ]);
      
      return submission;
    } catch (error) {
      LogService.instance.error('Error when creating submission: $error');
      rethrow;
    }
  }

  Future<void> updateSubmission({
    required String submissionId,
    List<String>? photos,
    String? comment,
  }) async {
    try {
      final updatedSubmission = await _repository.updateSubmission(
        submissionId: submissionId,
        photos: photos,
        comment: comment,
      );
      
      state = state.whenData((submissions) => submissions
          .map((s) => s.id == submissionId ? updatedSubmission : s)
          .toList());
    } catch (error) {
      LogService.instance.error('Error updating submission: $error');
      rethrow;
    }
  }

  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _repository.deleteSubmission(submissionId);
      state = state.whenData((submissions) =>
          submissions.where((s) => s.id != submissionId).toList());
    } catch (error) {
      LogService.instance.error('Error deleting submission: $error');
      rethrow;
    }
  }

  // Refresh submissions for a specific jam
  Future<void> refreshJamSubmissions(String jamId) async {
    try {
      final jamSubmissions = await _repository.getSubmissionsByJam(jamId);
      state = state.whenData((submissions) {
        final updatedSubmissions = submissions
            .where((submission) => submission.jamId != jamId)
            .toList()
          ..addAll(jamSubmissions);
        return updatedSubmissions;
      });
    } catch (error) {
      LogService.instance.error('Error refreshing jam submissions: $error');
      rethrow;
    }
  }

  // Refresh submissions for a specific user
  Future<void> refreshUserSubmissions(String userId) async {
    try {
      final userSubmissions = await _repository.getSubmissionsByUser(userId);
      state = state.whenData((submissions) {
        final updatedSubmissions = submissions
            .where((submission) => submission.userId != userId)
            .toList()
          ..addAll(userSubmissions);
        return updatedSubmissions;
      });
    } catch (error) {
      LogService.instance.error('Error refreshing user submissions: $error');
      rethrow;
    }
  }
}

// Extension method for list to support firstWhereOrNull
extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}