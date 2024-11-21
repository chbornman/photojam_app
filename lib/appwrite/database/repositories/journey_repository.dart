import 'package:photojam_app/appwrite/database/models/journey_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class JourneyRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionJourneys;

  JourneyRepository(this._db);

  Future<Journey> createJourney({
    required String title,
    required bool isActive,
    List<String> participantIds = const [],
    List<String> lessonIds = const [],
  }) async {
    try {
      final doc = await _db.createDocument(
        collectionId,
        {
          'title': title,
          'is_active': isActive,
          'participant_ids': participantIds,
          'lesson': lessonIds,
          'date_creation': DateTime.now().toIso8601String(),
          'date_updated': DateTime.now().toIso8601String(),
        },
      );
      return Journey.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating journey: $e');
      rethrow;
    }
  }

  Future<Journey> getJourneyById(String journeyId) async {
    try {
      final doc = await _db.getDocument(collectionId, journeyId);
      return Journey.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error fetching journey: $e');
      rethrow;
    }
  }

  Future<List<Journey>> getAllJourneys({bool activeOnly = false}) async {
    try {
      final queries = <String>[];
      if (activeOnly) {
        queries.add('equal("is_active", true)');
      }

      final docs = await _db.listDocuments(
        collectionId,
        queries: queries,
      );
      
      return docs.documents.map((doc) => Journey.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching all journeys: $e');
      rethrow;
    }
  }

  Future<List<Journey>> getJourneysByUser(String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          'search("participant_ids", "$userId")',
          'equal("is_active", true)',
        ],
      );
      return docs.documents.map((doc) => Journey.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching user journeys: $e');
      rethrow;
    }
  }

  Future<Journey> updateJourney(String journeyId, {
    String? title,
    bool? isActive,
    List<String>? lessonIds,
  }) async {
    try {
      final existingJourney = await getJourneyById(journeyId);
      
      final updatedData = {
        ...existingJourney.toJson(),
        if (title != null) 'title': title,
        if (isActive != null) 'is_active': isActive,
        if (lessonIds != null) 'lesson': lessonIds,
        'date_updated': DateTime.now().toIso8601String(),
      };

      await _db.updateDocument(
        collectionId,
        journeyId,
        updatedData,
      );

      return await getJourneyById(journeyId);
    } catch (e) {
      LogService.instance.error('Error updating journey: $e');
      rethrow;
    }
  }

  Future<void> addParticipantToJourney(String journeyId, String userId) async {
    try {
      final doc = await _db.getDocument(collectionId, journeyId);
      final journey = Journey.fromDocument(doc);
      
      if (!journey.participantIds.contains(userId)) {
        final updatedParticipants = [...journey.participantIds, userId];
        await _db.updateDocument(
          collectionId,
          journeyId,
          {
            ...journey.toJson(),
            'participant_ids': updatedParticipants,
            'date_updated': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      LogService.instance.error('Error adding participant to journey: $e');
      rethrow;
    }
  }

  Future<void> removeParticipantFromJourney(String journeyId, String userId) async {
    try {
      final doc = await _db.getDocument(collectionId, journeyId);
      final journey = Journey.fromDocument(doc);
      
      if (journey.participantIds.contains(userId)) {
        final updatedParticipants = journey.participantIds.where((id) => id != userId).toList();
        await _db.updateDocument(
          collectionId,
          journeyId,
          {
            ...journey.toJson(),
            'participant_ids': updatedParticipants,
            'date_updated': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      LogService.instance.error('Error removing participant from journey: $e');
      rethrow;
    }
  }

  Future<void> deleteJourney(String journeyId) async {
    try {
      await _db.deleteDocument(collectionId, journeyId);
    } catch (e) {
      LogService.instance.error('Error deleting journey: $e');
      rethrow;
    }
  }
}