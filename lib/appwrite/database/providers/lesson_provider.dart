import 'dart:typed_data';

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

class LessonsNotifier extends StateNotifier<AsyncValue<List<Lesson>>> {
  final LessonRepository _repository;
  
  LessonsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLessons();
  }

  Future<void> loadLessons() async {
    try {
      LogService.instance.info('Loading all lessons');
      state = const AsyncValue.loading();
      
      final allLessons = await _repository.getAllLessons();
      
      LogService.instance.info('Loaded ${allLessons.length} lessons');
      state = AsyncValue.data(allLessons);
    } catch (error, stackTrace) {
      LogService.instance.error('Error loading lessons: $error');
      LogService.instance.error('Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createLesson({
    required String fileName,
    required Uint8List fileBytes,
    String? journeyId,
    String? jamId,
  }) async {
    try {
      LogService.instance.info('Creating new lesson: $fileName');
            
      final newLesson = await _repository.createLesson(
        fileName: fileName,
        fileBytes: fileBytes,
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

  Future<void> updateLesson({
    required String lessonId, 
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      LogService.instance.info('Updating lesson: $lessonId');

      final updatedLesson = await _repository.updateLesson(
        docId: lessonId,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      LogService.instance.info('Successfully updated lesson: ${updatedLesson.id}');

      state = state.whenData((lessons) => lessons.map((lesson) =>
          lesson.id == lessonId ? updatedLesson : lesson).toList());
    } catch (error) {
      LogService.instance.error('Error updating lesson: $error');
      rethrow;
    }
  }

Future<void> deleteLesson({required String lessonId}) async {
  try {
    LogService.instance.info('Deleting lesson: $lessonId');

    await _repository.deleteLesson(lessonId);

    // Update the provider state by removing the deleted lesson
    state = state.whenData(
      (lessons) => lessons.where((lesson) => lesson.id != lessonId).toList(),
    );
  } catch (error) {
    LogService.instance.error('Error deleting lesson: $error');
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