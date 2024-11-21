import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/lesson_model.dart';
import 'package:photojam_app/appwrite/database/repositories/lesson_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Base repository provider
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  return LessonRepository(dbRepository);
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
    // Load initial lessons
    loadLessons();
  }

  Future<void> loadLessons() async {
    try {
      state = const AsyncValue.loading();
      // Since there's no getAllLessons in repository, we'll load them by querying
      // both journey and jam lessons - you might want to add getAllLessons to repository
      final List<Lesson> lessons = [];
      
      // For now, we'll update state with an empty list
      // TODO: Implement proper lesson loading strategy based on your needs
      state = AsyncValue.data(lessons);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error loading lessons: $error');
    }
  }

  Future<void> createLesson({
    required String title,
    required String content,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      await _repository.createLesson(
        title: title,
        content: content,
        version: 1,
        journeyId: journeyId,
        jamId: jamId,
      );
      await loadLessons();
    } catch (error) {
      LogService.instance.error('Error creating lesson: $error');
      rethrow;
    }
  }

  Future<void> updateLessonContent(String lessonId, String content) async {
    try {
      await _repository.updateLessonContent(lessonId, content);
      await loadLessons();
    } catch (error) {
      LogService.instance.error('Error updating lesson content: $error');
      rethrow;
    }
  }

  // Helper method to refresh lessons for a specific journey
  Future<void> refreshJourneyLessons(String journeyId) async {
    try {
      final journeyLessons = await _repository.getLessonsByJourney(journeyId);
      state = await state.whenData((lessons) {
        final updatedLessons = lessons
            .where((lesson) => lesson.journeyId != journeyId)
            .toList()
          ..addAll(journeyLessons);
        return updatedLessons;
      });
    } catch (error) {
      LogService.instance.error('Error refreshing journey lessons: $error');
      rethrow;
    }
  }

  // Helper method to refresh lesson for a specific jam
  Future<void> refreshJamLesson(String jamId) async {
    try {
      final jamLesson = await _repository.getLessonForJam(jamId);
      state = await state.whenData((lessons) {
        final updatedLessons = lessons
            .where((lesson) => lesson.jamId != jamId)
            .toList();
        if (jamLesson != null) {
          updatedLessons.add(jamLesson);
        }
        return updatedLessons;
      });
    } catch (error) {
      LogService.instance.error('Error refreshing jam lesson: $error');
      rethrow;
    }
  }
}

// Extension method for list to support firstWhereOrNull
extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}