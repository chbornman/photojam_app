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

  /// Validates submission input parameters
  void _validateSubmissionInput({
    required String userId,
    required String jamId,
    required List<String> photos,
  }) {
    if (userId.isEmpty) throw ArgumentError('userId cannot be empty');
    if (jamId.isEmpty) throw ArgumentError('jamId cannot be empty');
    if (photos.isEmpty) throw ArgumentError('photos cannot be empty');
  }

  /// Prepares submission data for database
  Map<String, dynamic> _prepareSubmissionData({
    required String userId,
    required String jamId,
    required List<String> photos,
    String? comment,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      'user_id': userId,
      'jam': {'\$id': jamId},
      'photos': photos,
      'comment': comment ?? '',
      'date_creation': now,
      'date_updated': now,
    };
  }

  Future<Submission> createSubmission({
    required String userId,
    required String jamId,
    required List<String> photos,
    String? comment,
  }) async {
    try {
      // Log initial submission attempt
      LogService.instance.info(
        'Creating submission - UserId: $userId, JamId: $jamId, Photos: ${photos.length}',
      );

      // Validate input parameters
      _validateSubmissionInput(
        userId: userId,
        jamId: jamId,
        photos: photos,
      );

      // Prepare submission data
      final data = _prepareSubmissionData(
        userId: userId,
        jamId: jamId,
        photos: photos,
        comment: comment,
      );

      // Create document
      final doc = await _db.createDocument(collectionId, data);
      LogService.instance.info('Created submission document: ${doc.$id}');

      // Parse and return submission
      return Submission.fromDocument(doc);
    } on ArgumentError catch (e) {
      LogService.instance.error('Validation error in createSubmission: $e');
      rethrow;
    } on AppwriteException catch (e) {
      LogService.instance.error(
        'Appwrite error in createSubmission: '
        'Code: ${e.code}, Type: ${e.type}, Message: ${e.message}',
      );
      rethrow;
    } catch (e) {
      LogService.instance.error('Unexpected error in createSubmission: $e');
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

  Future<List<Submission>> getAllSubmissions() async {
    try {
      LogService.instance.info('Fetching all submissions');
      final docs = await _db.listDocuments(collectionId);
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching all submissions: $e');
      rethrow;
    }
  }
}
