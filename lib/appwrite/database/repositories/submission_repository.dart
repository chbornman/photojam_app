import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class SubmissionRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionSubmissions;

  SubmissionRepository(this._db);

  Future<Submission> createSubmission({
    required String userId,
    required String jamId,
    required List<String> photos,
    String? comment,
  }) async {
    try {
      // Input validation with logging
      LogService.instance.info('Starting submission creation process...');
      LogService.instance.info('User ID: $userId');
      LogService.instance.info('Jam ID: $jamId');
      LogService.instance.info('Number of photos: ${photos.length}');
      LogService.instance.info('Photos: $photos');
      LogService.instance.info('Comment length: ${comment?.length ?? 0}');

      if (userId.isEmpty) {
        LogService.instance.error('Validation failed: userId is empty');
        throw ArgumentError('userId cannot be empty');
      }
      if (jamId.isEmpty) {
        LogService.instance.error('Validation failed: jamId is empty');
        throw ArgumentError('jamId cannot be empty');
      }
      if (photos.isEmpty) {
        LogService.instance.error('Validation failed: photos is empty');
        throw ArgumentError('photos cannot be empty');
      }

      final now = DateTime.now().toIso8601String();
      final data = {
        'user_id': userId,
        'jam': {'\$id': jamId},
        'photos': photos,
        'comment': comment ?? '',
        'date_creation': now,
        'date_updated': now,
      };

      LogService.instance.info('Prepared data for submission: $data');
      LogService.instance
          .info('Database repository instance: ${_db.toString()}');
      LogService.instance.info('Collection ID being used: $collectionId');

      // Log pre-creation state
      LogService.instance
          .info('Attempting to create document in collection: $collectionId');

      try {
        // Try to list documents to verify database access
        final testQuery = await _db.listDocuments(
          collectionId,
          queries: [Query.limit(1)],
        );
        LogService.instance.info(
            'Successfully tested database access. Can read documents: ${testQuery.documents.length}');
      } catch (e) {
        LogService.instance.error('Failed database access test: $e');
        if (e is AppwriteException) {
          LogService.instance.error('Database test error details - '
              'Code: ${e.code}, '
              'Type: ${e.type}, '
              'Message: ${e.message}');
        }
      }

      // Create document with extensive error handling
      Document? doc;
      try {
        LogService.instance.info('Making createDocument call...');
        doc = await _db.createDocument(
          collectionId,
          data,
        );
        LogService.instance
            .info('Document created successfully with ID: ${doc.$id}');
      } catch (createError) {
        LogService.instance
            .error('Error during createDocument call: $createError');
        if (createError is AppwriteException) {
          LogService.instance.error('Create document error details:');
          LogService.instance.error('  - Code: ${createError.code}');
          LogService.instance.error('  - Type: ${createError.type}');
          LogService.instance.error('  - Message: ${createError.message}');
          LogService.instance.error('  - Response: ${createError.response}');
        }
        rethrow;
      }

      // Parse the created document
      try {
        final submission = Submission.fromDocument(doc);
        LogService.instance.info(
            'Successfully created and parsed submission with ID: ${submission.id}');
        return submission;
      } catch (parseError) {
        LogService.instance
            .error('Error parsing created document: $parseError');
        LogService.instance.error('Document data: ${doc.data}');
        rethrow;
      }
    } catch (e) {
      LogService.instance.error('Top-level error in createSubmission: $e');
      if (e is AppwriteException) {
        LogService.instance.error('Appwrite error details - '
            'Code: ${e.code}, '
            'Type: ${e.type}, '
            'Message: ${e.message}, '
            'Response: ${e.response}');
      }
      rethrow;
    }
  }

  Future<Submission> getSubmissionById(String submissionId) async {
    try {
      final doc = await _db.getDocument(collectionId, submissionId);
      return Submission.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error fetching submission: $e');
      rethrow;
    }
  }

  Future<List<Submission>> getSubmissionsByUser(String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('user_id', userId),
        ],
      );
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching user submissions: $e');
      rethrow;
    }
  }

  Future<List<Submission>> getSubmissionsByJam(String jamId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('jam', jamId), // Changed from jam.$id to jam
        ],
      );
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching jam submissions: $e');
      rethrow;
    }
  }

  Future<Submission?> getUserSubmissionForJam(
      String jamId, String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('jam', jamId), // Changed from jam.$id to jam
          Query.equal('user_id', userId),
        ],
      );

      if (docs.documents.isEmpty) {
        return null;
      }

      return Submission.fromDocument(docs.documents.first);
    } catch (e) {
      LogService.instance.error('Error fetching user submission for jam: $e');
      rethrow;
    }
  }

  Future<Submission> updateSubmission({
    required String submissionId,
    List<String>? photos,
    String? comment,
  }) async {
    try {
      final existing = await getSubmissionById(submissionId);

      final updatedData = {
        'user_id': existing.userId,
        'jam': {'\$id': existing.jamId},
        'photos': photos ?? existing.photos,
        'comment': comment ?? existing.comment ?? '',
        'date_creation': existing.dateCreation.toIso8601String(),
        'date_updated': DateTime.now().toIso8601String(),
      };

      await _db.updateDocument(
        collectionId,
        submissionId,
        updatedData,
      );

      return await getSubmissionById(submissionId);
    } catch (e) {
      LogService.instance.error('Error updating submission: $e');
      rethrow;
    }
  }

  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _db.deleteDocument(collectionId, submissionId);
    } catch (e) {
      LogService.instance.error('Error deleting submission: $e');
      rethrow;
    }
  }
}
