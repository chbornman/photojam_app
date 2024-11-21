import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/journey_model.dart';
import 'package:photojam_app/appwrite/database/repositories/journey_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';


// Update the journey repository provider to use it
final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  return JourneyRepository(dbRepository);
});
// State for storing all journeys
final journeysProvider = StateNotifierProvider<JourneysNotifier, AsyncValue<List<Journey>>>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  return JourneysNotifier(repository);
});

// Provider for active journeys only
final activeJourneysProvider = Provider<AsyncValue<List<Journey>>>((ref) {
  return ref.watch(journeysProvider).whenData(
    (journeys) => journeys.where((journey) => journey.isActive).toList(),
  );
});

// Provider for a specific journey by ID
final journeyByIdProvider = Provider.family<AsyncValue<Journey?>, String>((ref, journeyId) {
  return ref.watch(journeysProvider).whenData(
    (journeys) => journeys.firstWhere((j) => j.id == journeyId),
  );
});

// Provider for user's journeys
final userJourneysProvider = Provider.family<AsyncValue<List<Journey>>, String>((ref, userId) {
  return ref.watch(journeysProvider).whenData(
    (journeys) => journeys.where((j) => j.participantIds.contains(userId)).toList(),
  );
});

class JourneysNotifier extends StateNotifier<AsyncValue<List<Journey>>> {
  final JourneyRepository _repository;

  JourneysNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load journeys when initialized
    loadJourneys();
  }

  Future<void> loadJourneys() async {
    try {
      state = const AsyncValue.loading();
      final journeys = await _repository.getAllJourneys();
      state = AsyncValue.data(journeys);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error loading journeys: $error');
    }
  }

  Future<void> createJourney({
    required String title,
    required bool isActive,
    List<String> participantIds = const [],
    List<String> lessonIds = const [],
  }) async {
    try {
      await _repository.createJourney(
        title: title,
        isActive: isActive,
        participantIds: participantIds,
        lessonIds: lessonIds,
      );
      await loadJourneys(); // Reload the list after creating
    } catch (error) {
      LogService.instance.error('Error creating journey: $error');
      rethrow;
    }
  }

  Future<void> updateJourney(
    String journeyId, {
    String? title,
    bool? isActive,
    List<String>? lessonIds,
  }) async {
    try {
      await _repository.updateJourney(
        journeyId,
        title: title,
        isActive: isActive,
        lessonIds: lessonIds,
      );
      await loadJourneys(); // Reload the list after updating
    } catch (error) {
      LogService.instance.error('Error updating journey: $error');
      rethrow;
    }
  }

  Future<void> addParticipant(String journeyId, String userId) async {
    try {
      await _repository.addParticipantToJourney(journeyId, userId);
      await loadJourneys();
    } catch (error) {
      LogService.instance.error('Error adding participant: $error');
      rethrow;
    }
  }

  Future<void> removeParticipant(String journeyId, String userId) async {
    try {
      await _repository.removeParticipantFromJourney(journeyId, userId);
      await loadJourneys();
    } catch (error) {
      LogService.instance.error('Error removing participant: $error');
      rethrow;
    }
  }

  Future<void> deleteJourney(String journeyId) async {
    try {
      await _repository.deleteJourney(journeyId);
      await loadJourneys();
    } catch (error) {
      LogService.instance.error('Error deleting journey: $error');
      rethrow;
    }
  }
}