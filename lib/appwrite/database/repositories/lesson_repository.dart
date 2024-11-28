import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
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
    required String title,
    required String content,
    required int version,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Creating lesson with title: $title');

      // First upload content to storage
      final contentFile = await _storage.uploadFile(
        '$title.md',
        Uint8List.fromList(content.codeUnits),
      );
      LogService.instance.info('Uploaded content file: ${contentFile.id}');

      // Get the file URL as a string - using direct storage access
      final contentUrl = _storage.storage
          .getFileView(
            bucketId: AppConstants.bucketLessonsId,
            fileId: contentFile.id,
          )
          .toString();
      LogService.instance.info('Generated content URL: $contentUrl');

      final now = DateTime.now().toIso8601String();

      final documentData = {
        'title': title,
        'content': contentUrl,
        'version': version,
        'is_active': true,
        'journey': journeyId != null ? {'\$id': journeyId} : null,
        'jam': jamId != null ? {'\$id': jamId} : null,
        'date_creation': now,
        'date_updated': now,
      };

      LogService.instance
          .info('Creating document in collection: $collectionId');
      LogService.instance.info('Document data: $documentData');

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

  Future<List<Lesson>> getLessonsByJourney(String journeyId) async {
    try {
      LogService.instance.info('Fetching lessons for journey: $journeyId');

      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('journey', journeyId),
          Query.equal('is_active', true),
        ],
      );

      final lessons =
          docs.documents.map((doc) => Lesson.fromDocument(doc)).toList();
      LogService.instance.info('Found ${lessons.length} lessons');

      return lessons;
    } catch (e) {
      LogService.instance.error('Error fetching journey lessons: $e');
      rethrow;
    }
  }

  Future<Lesson?> getLessonForJam(String jamId) async {
    try {
      LogService.instance.info('Fetching lesson for jam: $jamId');

      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('jam', jamId),
          Query.equal('is_active', true),
        ],
      );

      if (docs.documents.isEmpty) {
        LogService.instance.info('No lesson found for jam');
        return null;
      }

      LogService.instance.info('Found lesson: ${docs.documents.first.$id}');
      return Lesson.fromDocument(docs.documents.first);
    } catch (e) {
      LogService.instance.error('Error fetching jam lesson: $e');
      rethrow;
    }
  }

  Future<void> updateLessonContent(String lessonId, String content) async {
    try {
      LogService.instance.info('Updating content for lesson: $lessonId');

      final doc = await _db.getDocument(collectionId, lessonId);
      final lesson = Lesson.fromDocument(doc);

      // First update the content file
      final contentFile = await _storage.uploadFile(
        '$lessonId-v${lesson.version + 1}.md',
        Uint8List.fromList(content.codeUnits),
      );

      final contentUrl = await _storage.getFilePreviewUrl(
        contentFile.id,
      );

      LogService.instance.info('Updated content file: ${contentFile.id}');

      await _db.updateDocument(
        collectionId,
        lessonId,
        {
          ...lesson.toJson(),
          'content': contentUrl,
          'date_updated': DateTime.now().toIso8601String(),
          'version': lesson.version + 1,
        },
      );

      LogService.instance.info('Updated lesson document');
    } catch (e) {
      LogService.instance.error('Error updating lesson content: $e');
      rethrow;
    }
  }

  Future<Lesson> updateLesson({
    required String lessonId,
    String? title,
    String? content,
  }) async {
    try {
      LogService.instance.info('Beginning lesson update for: $lessonId');
      LogService.instance.info(
          'Update parameters - Title: $title, Has content: ${content != null}');

      final doc = await _db.getDocument(collectionId, lessonId);
      final lesson = Lesson.fromDocument(doc);
      final now = DateTime.now().toIso8601String();
      String contentUrl = lesson.content.toString();
      int newVersion = lesson.version;

      // If new content is provided, update the file in storage
      if (content != null) {
        LogService.instance.info('Updating lesson content file');

        // Delete old file if it exists
        try {
          final oldFileId = lesson.content.pathSegments.last;
          await _storage.deleteFile(oldFileId);
          LogService.instance.info('Deleted old content file: $oldFileId');
        } catch (e) {
          LogService.instance.error('Error deleting old content file: $e');
          // Continue with upload even if deletion fails
        }

        // Upload new content file
        final fileName = '${title ?? lesson.title}-v${lesson.version + 1}.md';
        final contentFile = await _storage.uploadFile(
          fileName,
          Uint8List.fromList(content.codeUnits),
        );
        LogService.instance
            .info('Uploaded new content file: ${contentFile.id}');

        // Get new file URL
        contentUrl = _storage.storage
            .getFileView(
              bucketId: AppConstants.bucketLessonsId,
              fileId: contentFile.id,
            )
            .toString();
        LogService.instance.info('Generated new content URL: $contentUrl');

        // Increment version when content is updated
        newVersion = lesson.version + 1;
      }

      // Prepare update data
      final updateData = {
        ...lesson.toJson(),
        if (title != null) 'title': title,
        'content': contentUrl,
        'version': newVersion,
        'date_updated': now,
      };

      LogService.instance.info('Updating lesson document with new data');
      LogService.instance.info('New version: $newVersion');

      final updatedDoc = await _db.updateDocument(
        collectionId,
        lessonId,
        updateData,
      );

      LogService.instance
          .info('Successfully updated lesson: ${updatedDoc.$id}');
      return Lesson.fromDocument(updatedDoc);
    } catch (e) {
      LogService.instance.error('Error updating lesson: $e');
      rethrow;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      LogService.instance.info('Deleting lesson: $lessonId');

      // First get the lesson to find its content file URL
      final doc = await _db.getDocument(collectionId, lessonId);
      final lesson = Lesson.fromDocument(doc);

      // Extract file ID from content URL
      final fileId = lesson.content.pathSegments.last;
      LogService.instance.info('Found associated file ID: $fileId');

      // Delete the content file from storage
      try {
        await _storage.deleteFile(fileId);
        LogService.instance.info('Deleted lesson file from storage: $fileId');
      } catch (e) {
        LogService.instance.error('Error deleting lesson file: $e');
        // Continue with document deletion even if file deletion fails
      }

      // Delete the lesson document
      await _db.deleteDocument(collectionId, lessonId);
      LogService.instance
          .info('Successfully deleted lesson document: $lessonId');
    } catch (e) {
      LogService.instance.error('Error deleting lesson: $e');
      rethrow;
    }
  }
}
