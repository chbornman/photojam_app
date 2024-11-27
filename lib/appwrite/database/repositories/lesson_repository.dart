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

      // First upload the content to storage
      final contentFile = await _storage.uploadFile(
        '$title.md',
        Uint8List.fromList(content.codeUnits),
      );
      LogService.instance.info('Uploaded content file: ${contentFile.id}');

      // Get the file URL - this needs to be a URL string, not the preview data
      final contentUrl = _storage.storage
          .getFileView(
            bucketId: AppConstants.bucketLessonsId,
            fileId: contentFile.id,
          )
          .toString();
      LogService.instance.info('Generated content URL: $contentUrl');

      final now = DateTime.now().toIso8601String();
      final permissions = [
        Permission.read(Role.any()),
        Permission.write(Role.team(AppConstants.appwriteTeamId, 'admin')),
        Permission.write(Role.team(AppConstants.appwriteTeamId, 'facilitator')),
      ];

      final doc = await _db.createDocument(
        collectionId,
        {
          'title': title,
          'content': contentUrl,
          'version': version,
          'is_active': true,
          'journey': journeyId != null ? {'\$id': journeyId} : null,
          'jam': jamId != null ? {'\$id': jamId} : null,
          'date_creation': now,
          'date_updated': now,
        },
        permissions: permissions,
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
}
