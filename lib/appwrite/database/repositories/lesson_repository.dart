import 'dart:convert';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdown_processor.dart';
import 'package:path/path.dart' as path;

class LessonRepository {
  final DatabaseRepository _db;
  final StorageNotifier _storage;
  final String collectionId = AppConstants.collectionLessons;

  LessonRepository(this._db, this._storage);
  Future<Lesson> createLesson({
    required String mdFileName,
    required Uint8List mdFileBytes,
    required Map<String, Uint8List> otherFiles,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Create Lesson for: $mdFileName');

      final lessonId = ID.unique();
      final markdownProcessor = MarkdownProcessor();

      // Process markdown to handle images
      final processedMarkdown = await markdownProcessor.processMarkdown(
        markdownContent: utf8.decode(mdFileBytes),
        otherFiles: otherFiles,
        lessonId: lessonId,
      );

      // Upload all images
      final uploadedImageIds = <String>[];
      for (final entry in processedMarkdown.images.entries) {
        final imageFile = await _storage.uploadFile(
          entry.key,
          entry.value,
        );
        uploadedImageIds.add(imageFile.id);
        LogService.instance.info('Uploaded image: ${imageFile.id}');
      }

      // Upload markdown content
      final file = await _storage.uploadFile(
        mdFileName,
        utf8.encode(processedMarkdown.content),
      );
      LogService.instance.info("Markdown file uploaded: ${file.id}");

      final now = DateTime.now().toIso8601String();
      final documentData = {
        'title': mdFileName,
        'contentFileId': file.id,
        'version': 1,
        'is_active': true,
        'journey': journeyId != null ? {'\$id': journeyId} : null,
        'jam': jamId != null ? {'\$id': jamId} : null,
        'date_creation': now,
        'date_updated': now,
        'image_ids': uploadedImageIds,
      };

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
    required Map<String, Uint8List> otherFiles,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Updating Lesson: $fileName (docId: $docId)');

      // Delete existing lesson and its images
      await deleteLesson(docId);

      // Create new lesson with processed content
      return await createLesson(
        mdFileName: fileName,
        mdFileBytes: fileBytes,
        otherFiles: otherFiles,
        journeyId: journeyId,
        jamId: jamId,
      );
    } catch (e) {
      LogService.instance.error('Error updating lesson: $e');
      rethrow;
    }
  }

  Future<void> deleteLesson(String docId) async {
    try {
      LogService.instance.info('Deleting Lesson with docId: $docId');

      // Get document to find associated files
      final doc = await _db.getDocument(collectionId, docId);
      final content = await _storage.downloadFile(doc.data['contentFileId']);

      // Parse markdown to find image references
      final markdownText = utf8.decode(content);
      final imageRefs = _extractImageRefs(markdownText);

      // Delete all images
      for (final imageRef in imageRefs) {
        final imageId = path.basename(imageRef);
        await _storage.deleteFile(imageId);
        LogService.instance.info('Deleted image: $imageId');
      }

      // Delete markdown file
      await _storage.deleteFile(doc.data['contentFileId']);
      LogService.instance
          .info('Deleted markdown file: ${doc.data['contentFileId']}');

      // Delete document
      await _db.deleteDocument(collectionId, docId);
      LogService.instance.info('Deleted lesson document: $docId');
    } catch (e) {
      LogService.instance.error('Error deleting lesson: $e');
      rethrow;
    }
  }

  List<String> _extractImageRefs(String markdown) {
    final imageRefs = <String>[];
    final matches = RegExp(r'!\[.*?\]\((.*?)\)').allMatches(markdown);

    for (final match in matches) {
      final path = match.group(1);
      if (path != null && path.startsWith('/lessons/')) {
        imageRefs.add(path);
      }
    }

    return imageRefs;
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
