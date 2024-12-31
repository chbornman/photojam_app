import 'dart:typed_data';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class LessonRepository {
  final DatabaseRepository _db;
  final StorageNotifier _storage;
  final String collectionId = AppConstants.collectionLessons;

  LessonRepository(this._db, this._storage);

  Future<Lesson> createLesson({
    required String fileName,
    required Uint8List fileBytes,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Create Lesson for: $fileName');

      // Upload File to storage
      final file = await _storage.uploadFile(fileName, fileBytes);
      LogService.instance.info("File uploaded successfully: ${file.id}");

      final now = DateTime.now().toIso8601String();

      final documentData = {
        'title': fileName,
        'contentFileId': file.id,
        'version': 1,
        'is_active': true,
        'journey': journeyId != null ? {'\$id': journeyId} : null,
        'jam': jamId != null ? {'\$id': jamId} : null,
        'date_creation': now,
        'date_updated': now,
      };

      LogService.instance.info(
          'Creating document in collection: $collectionId Document data: $documentData');

      final doc = await _db.createDocument(
        collectionId,
        documentData,
      );

      LogService.instance.info('Created lesson document: ${doc.$id}');
      return Lesson.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating lesson: $e');
      rethrow;
    }
  }

  Future<Lesson> updateLesson({
    required String docId,
    required String fileName,
    required Uint8List fileBytes,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Updating Lesson: $fileName (docId: $docId)');

      // 1. Fetch the existing document
      final existingDoc = await _db.getDocument(collectionId, docId);
      final oldFileId = existingDoc.data['contentFileId'];

      // 2. Increment the version
      final oldVersion = existingDoc.data['version'] ?? 1;
      final newVersion = oldVersion + 1;

      // 3. Delete the old file if it exists
      if (oldFileId != null && oldFileId is String && oldFileId.isNotEmpty) {
        await _storage.deleteFile(oldFileId);
        LogService.instance.info('Deleted old file: $oldFileId');
      }

      // 4. Upload the new file
      final newFile = await _storage.uploadFile(fileName, fileBytes);
      LogService.instance.info("New file uploaded: ${newFile.id}");

      // 5. Prepare updated fields
      final now = DateTime.now().toIso8601String();
      final updatedData = <String, dynamic>{
        'title': fileName,
        'contentFileId': newFile.id,
        'version': newVersion,
        'date_updated': now,
        if (journeyId != null) 'journey': {'\$id': journeyId},
        if (jamId != null) 'jam': {'\$id': jamId},
      };

      // 6. Update the document
      final doc = await _db.updateDocument(collectionId, docId, updatedData);
      LogService.instance.info('Updated lesson document: ${doc.$id}');

      return Lesson.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error updating lesson: $e');
      rethrow;
    }
  }

  Future<void> deleteLesson(String docId) async {
    try {
      LogService.instance.info('Deleting Lesson with docId: $docId');

      // 1. Retrieve the document so we know which file to remove
      final existingDoc = await _db.getDocument(collectionId, docId);
      final oldFileId = existingDoc.data['contentFileId'];

      // 2. Delete the associated file (if any)
      if (oldFileId != null && oldFileId is String && oldFileId.isNotEmpty) {
        await _storage.deleteFile(oldFileId);
        LogService.instance.info('Deleted file: $oldFileId');
      } else {
        LogService.instance.info('No file found to delete for docId: $docId');
      }

      // 3. Finally, delete the document itself
      await _db.deleteDocument(collectionId, docId);
      LogService.instance.info('Deleted lesson document: $docId');
    } catch (e) {
      LogService.instance.error('Error deleting lesson (docId: $docId): $e');
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
