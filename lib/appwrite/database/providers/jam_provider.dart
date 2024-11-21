import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/repositories/jam_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Base repository provider
final jamRepositoryProvider = Provider<JamRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  return JamRepository(dbRepository);
});

// Main state notifier provider for all jams
final jamsProvider = StateNotifierProvider<JamsNotifier, AsyncValue<List<Jam>>>((ref) {
  final repository = ref.watch(jamRepositoryProvider);
  return JamsNotifier(repository);
});

// Provider for upcoming jams (after current datetime)
final upcomingJamsProvider = Provider<AsyncValue<List<Jam>>>((ref) {
  return ref.watch(jamsProvider).whenData(
    (jams) => jams
        .where((jam) => jam.eventDatetime.isAfter(DateTime.now()))
        .toList()
        ..sort((a, b) => a.eventDatetime.compareTo(b.eventDatetime)),
  );
});

// Provider for jams by facilitator
final facilitatorJamsProvider = Provider.family<AsyncValue<List<Jam>>, String>((ref, facilitatorId) {
  return ref.watch(jamsProvider).whenData(
    (jams) => jams
        .where((jam) => jam.facilitatorId == facilitatorId)
        .toList()
        ..sort((a, b) => b.eventDatetime.compareTo(a.eventDatetime)),
  );
});

// Provider for jams by date range
final jamsInDateRangeProvider = Provider.family<AsyncValue<List<Jam>>, ({DateTime start, DateTime end})>((ref, range) {
  return ref.watch(jamsProvider).whenData(
    (jams) => jams
        .where((jam) => jam.eventDatetime.isAfter(range.start) && jam.eventDatetime.isBefore(range.end))
        .toList()
        ..sort((a, b) => a.eventDatetime.compareTo(b.eventDatetime)),
  );
});

// Provider for a specific jam by ID
final jamByIdProvider = Provider.family<AsyncValue<Jam?>, String>((ref, jamId) {
  return ref.watch(jamsProvider).whenData(
    (jams) => jams.firstWhere((j) => j.id == jamId),
  );
});

// Provider for upcoming jams by user
final userUpcomingJamsProvider = Provider.family<AsyncValue<List<Jam>>, String>((ref, userId) {
  return ref.watch(jamsProvider).whenData((jams) {
    final userJams = jams.where((jam) => 
      jam.submissionIds.any((submissionId) => submissionId.contains(userId)) &&
      jam.eventDatetime.isAfter(DateTime.now())
    ).toList();
    userJams.sort((a, b) => a.eventDatetime.compareTo(b.eventDatetime));
    return userJams;
  });
});

class JamsNotifier extends StateNotifier<AsyncValue<List<Jam>>> {
  final JamRepository _repository;

  JamsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadJams();
  }

  Future<void> loadJams() async {
    try {
      state = const AsyncValue.loading();
      final jams = await _repository.getAllJams();
      state = AsyncValue.data(jams);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error loading jams: $error');
    }
  }

  Future<void> createJam(Jam jam) async {
    try {
      await _repository.createJam(jam);
      await loadJams();
    } catch (error) {
      LogService.instance.error('Error creating jam: $error');
      rethrow;
    }
  }

  Future<void> updateJam(
    String jamId, {
    String? title,
    DateTime? eventDatetime,
    String? zoomLink,
    List<String>? selectedPhotos,
  }) async {
    try {
      await _repository.updateJam(
        jamId,
        title: title,
        eventDatetime: eventDatetime,
        zoomLink: zoomLink,
        selectedPhotos: selectedPhotos,
      );
      await loadJams();
    } catch (error) {
      LogService.instance.error('Error updating jam: $error');
      rethrow;
    }
  }

  Future<void> updateFacilitator(String jamId, String? facilitatorId) async {
    try {
      await _repository.updateJamFacilitator(jamId, facilitatorId);
      await loadJams();
    } catch (error) {
      LogService.instance.error('Error updating jam facilitator: $error');
      rethrow;
    }
  }

  Future<void> addSubmission(String jamId, String submissionId) async {
    try {
      await _repository.addSubmissionToJam(jamId, submissionId);
      await loadJams();
    } catch (error) {
      LogService.instance.error('Error adding submission to jam: $error');
      rethrow;
    }
  }

  Future<void> deleteJam(String jamId) async {
    try {
      await _repository.deleteJam(jamId);
      await loadJams();
    } catch (error) {
      LogService.instance.error('Error deleting jam: $error');
      rethrow;
    }
  }
}