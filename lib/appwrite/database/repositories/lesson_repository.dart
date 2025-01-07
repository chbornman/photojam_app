import 'dart:convert';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdown_processor.dart';

class LessonRepository {
  final DatabaseRepository _db;
  final StorageNotifier _storage;
  final String collectionId = AppConstants.collectionLessons;

  LessonRepository(this._db, this._storage);

  /// Example createLesson that delegates all uploading/document creation
  /// to the MarkdownProcessor. Now no longer does any upload or doc creation here.
  Future<Lesson> createLesson({
    required String mdFileName,
    required Uint8List mdFileBytes,
    required Map<String, Uint8List> otherFiles,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Create Lesson for: $mdFileName');

      // Generate a unique ID for the lesson
      final lessonId = ID.unique();

      // We simply call processMarkdown which does all the heavy lifting now
      final markdownProcessor = MarkdownProcessor(_storage, _db);

      await markdownProcessor.processMarkdown(
        markdownContent: utf8.decode(mdFileBytes),
        lessonId: lessonId,
        otherFiles: otherFiles,
        mdFileName: mdFileName,
        journeyId: journeyId,
        jamId: jamId,
      );

      // If you'd like, you can still do some post-processing or fetch
      // the newly created doc from the DB. That way you can return a Lesson model.
      // Or, if you prefer, just return a dummy for now:
      // final doc = await _db.getDocument(collectionId, <someID>);
      // return Lesson.fromDocument(doc);

      // For demonstration, returning an empty/placeholder lesson:
      return Lesson(
        id: lessonId,
        title: mdFileName,
        contentFileId: '', // or fetch from DB if needed
        version: 1,
        isActive: true,
        dateCreation: DateTime.now(),
        dateUpdated: DateTime.now(),
        imageIds: [],
        // fill other fields accordingly
      );
    } catch (e) {
      LogService.instance.error('Error creating lesson: $e');
      rethrow;
    }
  }

  Future<void> deleteLesson(String docId) async {
    try {
      LogService.instance.info('Starting deletion process for lesson: $docId');
      
      // First, try to get the document and all its associated data in one go
      final doc = await _db.getDocument(collectionId, docId);
      final imageIds = List<String>.from(doc.data['image_ids'] ?? []);
      final contentFileId = doc.data['contentFileId'] as String?;
      
      // Store all deletion errors to handle them appropriately
      final errors = <String>[];
      
      // Delete images if they exist
      if (imageIds.isNotEmpty) {
        for (final imageId in imageIds) {
          try {
            await _storage.deleteFile(imageId);
            LogService.instance.info('Deleted image: $imageId');
          } catch (e) {
            // Log but continue with other deletions
            errors.add('Failed to delete image $imageId: $e');
            LogService.instance.error('Error deleting image $imageId: $e');
          }
        }
      }
      
      // Delete markdown file if it exists
      if (contentFileId != null) {
        try {
          await _storage.deleteFile(contentFileId);
          LogService.instance.info('Deleted markdown file: $contentFileId');
        } catch (e) {
          errors.add('Failed to delete content file: $e');
          LogService.instance.error('Error deleting content file: $e');
        }
      }
      
      // Finally delete the document itself
      try {
        await _db.deleteDocument(collectionId, docId);
        LogService.instance.info('Deleted lesson document: $docId');
      } catch (e) {
        errors.add('Failed to delete lesson document: $e');
        LogService.instance.error('Error deleting lesson document: $e');
        throw AppwriteException('Failed to delete lesson: ${errors.join(", ")}');
      }
      
      // If we had any errors during the process, throw them all together
      if (errors.isNotEmpty) {
        throw AppwriteException('Partial deletion occurred: ${errors.join(", ")}');
      }
      
    } catch (e) {
      LogService.instance.error('Error in deleteLesson: $e');
      rethrow;
    }
  }

  Future<List<Lesson>> getAllLessons() async {
    try {
      // Log the action
      LogService.instance
          .info('Retrieving all Lessons for collection: $collectionId');

      // Fetch the documents (assuming listDocuments returns something like a DocumentList or similar)
      final docList = await _db.listDocuments(collectionId);

      // Convert each document to a Lesson
      final lessons =
          docList.documents.map((doc) => Lesson.fromDocument(doc)).toList();

      return lessons;
    } catch (e) {
      LogService.instance.error('Error retrieving all lessons: $e');
      rethrow;
    }
  }

  Future<Lesson?> getLessonByID(String lessonId) async {
    try {
      LogService.instance.info('Fetching lesson with ID: $lessonId');

      final doc = await _db.getDocument(collectionId, lessonId);
      LogService.instance.info('Fetched lesson document: ${doc.$id}');

      return Lesson.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error fetching lesson by ID: $e');
      rethrow;
    }
  }
}
