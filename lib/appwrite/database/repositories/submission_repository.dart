import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class SubmissionRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionSubmissions;

  SubmissionRepository(this._db);

  // Create submission (already well implemented!)
  Future<Submission> createSubmission({
    required String userId,
    required String jamId,
    required List<String> photos,
    String? comment,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final doc = await _db.createDocument(
        collectionId,
        {
          'user_id': userId,
          'jam': jamId,
          'photos': photos,
          'comment': comment,
          'date_creation': now,
          'date_updated': now,
        },
      );
      return Submission.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating submission: $e');
      rethrow;
    }
  }

  // Get submission by ID
  Future<Submission> getSubmissionById(String submissionId) async {
    try {
      final doc = await _db.getDocument(collectionId, submissionId);
      return Submission.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error fetching submission: $e');
      rethrow;
    }
  }

  // Get user submissions (already well implemented!)
  Future<List<Submission>> getSubmissionsByUser(String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: ['equal("user_id", "$userId")'],
      );
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching user submissions: $e');
      rethrow;
    }
  }

  // Get submissions for a jam
  Future<List<Submission>> getSubmissionsByJam(String jamId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: ['equal("jam", "$jamId")'],
      );
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching jam submissions: $e');
      rethrow;
    }
  }

  // Get user's submission for a specific jam (already well implemented!)
  Future<Submission?> getSubmissionForJam(String jamId, String userId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          'equal("jam", "$jamId")',
          'equal("user_id", "$userId")',
        ],
      );
      return docs.documents.isNotEmpty
          ? Submission.fromDocument(docs.documents.first)
          : null;
    } catch (e) {
      LogService.instance.error('Error fetching jam submission: $e');
      rethrow;
    }
  }

  // Update submission
  Future<Submission> updateSubmission({
    required String submissionId,
    List<String>? photos,
    String? comment,
  }) async {
    try {
      final existing = await getSubmissionById(submissionId);
      
      final updatedData = {
        ...existing.toJson(),
        if (photos != null) 'photos': photos,
        if (comment != null) 'comment': comment,
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

  // Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _db.deleteDocument(collectionId, submissionId);
    } catch (e) {
      LogService.instance.error('Error deleting submission: $e');
      rethrow;
    }
  }

  // Get submissions within date range (new useful method)
  Future<List<Submission>> getSubmissionsByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
    String? jamId,
  }) async {
    try {
      final queries = [
        'greaterThan("date_creation", "${start.toIso8601String()}")',
        'lessThan("date_creation", "${end.toIso8601String()}")',
        if (userId != null) 'equal("user_id", "$userId")',
        if (jamId != null) 'equal("jam", "$jamId")',
      ];

      final docs = await _db.listDocuments(
        collectionId,
        queries: queries,
      );
      
      return docs.documents.map((doc) => Submission.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching submissions by date range: $e');
      rethrow;
    }
  }
}