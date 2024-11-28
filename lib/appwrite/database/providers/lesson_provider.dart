import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/lesson_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Base repository provider
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  final storageNotifier = ref.watch(lessonStorageProvider.notifier);
  return LessonRepository(dbRepository, storageNotifier);
});

// Main state notifier provider for all lessons
final lessonsProvider = StateNotifierProvider<LessonsNotifier, AsyncValue<List<Lesson>>>((ref) {
  final repository = ref.watch(lessonRepositoryProvider);
  return LessonsNotifier(repository);
});

// Provider for lessons by journey ID
final journeyLessonsProvider = Provider.family<AsyncValue<List<Lesson>>, String>((ref, journeyId) {
  return ref.watch(lessonsProvider).whenData(
    (lessons) => lessons
        .where((lesson) => lesson.journeyId == journeyId && lesson.isActive)
        .toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation)),
  );
});

// Provider for getting a lesson for a specific jam
final jamLessonProvider = Provider.family<AsyncValue<Lesson?>, String>((ref, jamId) {
  return ref.watch(lessonsProvider).whenData(
    (lessons) => lessons.firstWhereOrNull(
      (lesson) => lesson.jamId == jamId && lesson.isActive,
    ),
  );
});

// Provider for a specific lesson by ID
final lessonByIdProvider = Provider.family<AsyncValue<Lesson?>, String>((ref, lessonId) {
  return ref.watch(lessonsProvider).whenData(
    (lessons) => lessons.firstWhereOrNull((l) => l.id == lessonId),
  );
});

// Provider for latest lesson version
final latestLessonVersionProvider = Provider.family<AsyncValue<int>, String>((ref, lessonId) {
  return ref.watch(lessonByIdProvider(lessonId)).whenData(
    (lesson) => lesson?.version ?? 0,
  );
});


class LessonsNotifier extends StateNotifier<AsyncValue<List<Lesson>>> {
  final LessonRepository _repository;
  
  LessonsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLessons();
  }

  Future<void> loadLessons() async {
    try {
      LogService.instance.info('Loading all lessons');
      state = const AsyncValue.loading();
      
      // Load journey lessons
      final journeyLessons = await _repository.getLessonsByJourney('');
      
      // Load jam lessons
      final jamLessons = await _repository.getLessonForJam('');
      
      final allLessons = <Lesson>[...journeyLessons];
      if (jamLessons != null) {
        allLessons.add(jamLessons);
      }
      
      LogService.instance.info('Loaded ${allLessons.length} lessons');
      state = AsyncValue.data(allLessons);
    } catch (error, stackTrace) {
      LogService.instance.error('Error loading lessons: $error');
      LogService.instance.error('Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createLesson({
    required String title,
    required String content,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Creating new lesson: $title');
      
      final newLesson = await _repository.createLesson(
        title: title,
        content: content,
        version: 1,
        journeyId: journeyId,
        jamId: jamId,
      );

      LogService.instance.info('Created lesson with ID: ${newLesson.id}');
      
      state = state.whenData((lessons) => [...lessons, newLesson]);
    } catch (error) {
      LogService.instance.error('Error creating lesson: $error');
      rethrow;
    }
  }

  Future<void> updateLesson(
    String lessonId, {
    String? title,
    String? content,
  }) async {
    try {
      LogService.instance.info('Updating lesson: $lessonId');
      LogService.instance.info('Update params - Title: $title, Has content: ${content != null}');

      final updatedLesson = await _repository.updateLesson(
        lessonId: lessonId,
        title: title,
        content: content,
      );

      LogService.instance.info('Successfully updated lesson: ${updatedLesson.id}');

      state = state.whenData((lessons) => lessons.map((lesson) =>
          lesson.id == lessonId ? updatedLesson : lesson).toList());
    } catch (error) {
      LogService.instance.error('Error updating lesson: $error');
      rethrow;
    }
  }

  Future<void> updateLessonContent(String lessonId, String content) async {
    try {
      LogService.instance.info('Updating lesson content: $lessonId');
      
      await _repository.updateLessonContent(lessonId, content);
      await loadLessons(); // Reload to get updated version
      
      LogService.instance.info('Successfully updated lesson content');
    } catch (error) {
      LogService.instance.error('Error updating lesson content: $error');
      rethrow;
    }
  }

  Future<void> deleteLessonContent(String lessonId) async {
    try {
      LogService.instance.info('Attempting to delete lesson: $lessonId');
      
      await _repository.deleteLesson(lessonId);
      
      state = state.whenData((lessons) => 
        lessons.where((lesson) => lesson.id != lessonId).toList()
      );
      
      LogService.instance.info('Successfully deleted lesson: $lessonId');
    } catch (error) {
      LogService.instance.error('Error deleting lesson: $error');
      await loadLessons(); // Reload on error to ensure consistency
      rethrow;
    }
  }

  Future<void> refreshJourneyLessons(String journeyId) async {
    try {
      LogService.instance.info('Refreshing lessons for journey: $journeyId');
      
      final journeyLessons = await _repository.getLessonsByJourney(journeyId);
      
      state = state.whenData((lessons) {
        final updatedLessons = lessons
            .where((lesson) => lesson.journeyId != journeyId)
            .toList()
          ..addAll(journeyLessons);
        return updatedLessons;
      });
      
      LogService.instance.info('Successfully refreshed journey lessons');
    } catch (error) {
      LogService.instance.error('Error refreshing journey lessons: $error');
      rethrow;
    }
  }

  Future<void> refreshJamLesson(String jamId) async {
    try {
      LogService.instance.info('Refreshing lesson for jam: $jamId');
      
      final jamLesson = await _repository.getLessonForJam(jamId);
      
      state = state.whenData((lessons) {
        final updatedLessons = lessons
            .where((lesson) => lesson.jamId != jamId)
            .toList();
        if (jamLesson != null) {
          updatedLessons.add(jamLesson);
        }
        return updatedLessons;
      });
      
      LogService.instance.info('Successfully refreshed jam lesson');
    } catch (error) {
      LogService.instance.error('Error refreshing jam lesson: $error');
      rethrow;
    }
  }
}extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}