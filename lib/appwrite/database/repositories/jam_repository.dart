import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class JamRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionJams;

  JamRepository(this._db);

  Future<Jam> createJam(Jam jam) async {
    try {
      final doc = await _db.createDocument(
        collectionId,
        jam.toJson(),
      );
      return Jam.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating jam: $e');
      rethrow;
    }
  }

  Future<Jam> getJamById(String jamId) async {
    try {
      final doc = await _db.getDocument(collectionId, jamId);
      return Jam.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error fetching jam: $e');
      rethrow;
    }
  }

  Future<List<Jam>> getUpcomingJamsByUser(String userId) async {
    try {
      final submissions = await _db.listDocuments(
        'photojam-collection-submission',
        queries: [Query.equal('user_id', userId)],
      );

      final jamIds = submissions.documents
          .map((doc) => doc.data['jam']['\$id'])
          .toSet()
          .toList();

      final now = DateTime.now();
      List<Jam> upcomingJams = [];

      for (String jamId in jamIds) {
        final jam = await getJamById(jamId);
        if (jam.eventDatetime.isAfter(now)) {
          upcomingJams.add(jam);
        }
      }

      return upcomingJams;
    } catch (e) {
      LogService.instance.error('Error fetching upcoming jams: $e');
      rethrow;
    }
  }

  Future<void> updateJamFacilitator(String jamId, String? facilitatorId) async {
    try {
      final jam = await getJamById(jamId);

      await _db.updateDocument(
        collectionId,
        jamId,
        {
          ...jam.toJson(),
          'facilitator_id': facilitatorId,
        },
      );
    } catch (e) {
      LogService.instance.error('Error updating jam facilitator: $e');
      rethrow;
    }
  }

  Future<Jam> updateJam(
    String jamId, {
    String? title,
    DateTime? eventDatetime,
    String? zoomLink,
    List<String>? selectedPhotos,
  }) async {
    try {
      final existingJam = await getJamById(jamId);

      final updatedData = {
        ...existingJam.toJson(),
        if (title != null) 'title': title,
        if (eventDatetime != null)
          'event_datetime': eventDatetime.toIso8601String(),
        if (zoomLink != null) 'zoom_link': zoomLink,
        if (selectedPhotos != null) 'selected_photos': selectedPhotos,
        'date_updated': DateTime.now().toIso8601String(),
      };

      final doc = await _db.updateDocument(
        collectionId,
        jamId,
        updatedData,
      );

      return Jam.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error updating jam: $e');
      rethrow;
    }
  }

  Future<void> deleteJam(String jamId) async {
    try {
      await _db.deleteDocument(collectionId, jamId);
    } catch (e) {
      LogService.instance.error('Error deleting jam: $e');
      rethrow;
    }
  }

Future<List<Jam>> getAllJams({
  bool activeOnly = true,
  DateTime? after,
}) async {
  try {
    final queries = <String>[];

    if (activeOnly) {
      queries.add(Query.equal('is_active', true));
    }

    if (after != null) {
      queries.add(Query.greaterThan('event_datetime', after.toIso8601String()));
    }

    final docs = await _db.listDocuments(
      collectionId,
      queries: queries,
    );

    return docs.documents.map((doc) => Jam.fromDocument(doc)).toList();
  } catch (e) {
    LogService.instance.error('Error fetching all jams: $e');
    rethrow;
  }
}

  Future<void> addSubmissionToJam(String jamId, String submissionId) async {
    try {
      final jam = await getJamById(jamId);
      final submissions = [...jam.submissionIds, submissionId];

      await _db.updateDocument(
        collectionId,
        jamId,
        {
          ...jam.toJson(),
          'submission': submissions,
          'date_updated': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      LogService.instance.error('Error adding submission to jam: $e');
      rethrow;
    }
  }

  Future<List<Jam>> getJamsByDateRange(DateTime start, DateTime end) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          'greaterThan("event_datetime", "${start.toIso8601String()}")',
          'lessThan("event_datetime", "${end.toIso8601String()}")',
        ],
      );
      return docs.documents.map((doc) => Jam.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching jams by date range: $e');
      rethrow;
    }
  }

  Future<List<Jam>> getJamsByFacilitator(String facilitatorId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: ['equal("facilitator_id", "$facilitatorId")'],
      );
      return docs.documents.map((doc) => Jam.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching jams by facilitator: $e');
      rethrow;
    }
  }

    Future<List<Jam>> getJamsByUserId(String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: ['equal("user_id", "$userId")'],
      );
      return docs.documents.map((doc) => Jam.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching jams by facilitator: $e');
      rethrow;
    }
  }
}
