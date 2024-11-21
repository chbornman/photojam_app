
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class LessonRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionLessons;

  LessonRepository(this._db);

  Future<Lesson> createLesson({
    required String title,
    required String content,
    required int version,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final doc = await _db.createDocument(
        collectionId,
        {
          'title': title,
          'content': content,
          'version': version,
          'is_active': true,
          'journey': journeyId,
          'jam': jamId,
          'date_creation': now,
          'date_updated': now,
        },
      );
      return Lesson.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating lesson: $e');
      rethrow;
    }
  }

  Future<List<Lesson>> getLessonsByJourney(String journeyId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('journey', journeyId),
          Query.equal('is_active', true),
        ],
      );
      return docs.documents.map((doc) => Lesson.fromDocument(doc)).toList();
    } catch (e) {
      LogService.instance.error('Error fetching journey lessons: $e');
      rethrow;
    }
  }

  Future<Lesson?> getLessonForJam(String jamId) async {
    try {
      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('jam', jamId),
          Query.equal('is_active', true),
        ],
      );
      return docs.documents.isNotEmpty 
          ? Lesson.fromDocument(docs.documents.first)
          : null;
    } catch (e) {
      LogService.instance.error('Error fetching jam lesson: $e');
      rethrow;
    }
  }

  Future<void> updateLessonContent(String lessonId, String content) async {
    try {
      final doc = await _db.getDocument(collectionId, lessonId);
      final lesson = Lesson.fromDocument(doc);
      
      await _db.updateDocument(
        collectionId,
        lessonId,
        {
          ...lesson.toJson(),
          'content': content,
          'date_updated': DateTime.now().toIso8601String(),
          'version': lesson.version + 1,
        },
      );
    } catch (e) {
      LogService.instance.error('Error updating lesson content: $e');
      rethrow;
    }
  }
}