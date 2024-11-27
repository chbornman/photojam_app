import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_database_repository.dart';
import 'package:photojam_app/appwrite/database/models/globals_model.dart';
import 'package:photojam_app/appwrite/database/repositories/globals_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Base repository provider
final globalsRepositoryProvider = Provider<GlobalsRepository>((ref) {
  final dbRepository = ref.watch(databaseRepositoryProvider);
  return GlobalsRepository(dbRepository);
});

// Main state notifier provider for all globals
final globalsProvider = StateNotifierProvider<GlobalsNotifier, AsyncValue<List<Globals>>>((ref) {
  final repository = ref.watch(globalsRepositoryProvider);
  return GlobalsNotifier(repository);
});

// Provider for getting a specific global by its key
final globalByKeyProvider = Provider.family<AsyncValue<Globals?>, String>((ref, key) {
  return ref.watch(globalsProvider).whenData(
    (globals) => globals.firstWhereOrNull((global) => global.key == key),
  );
});

// Provider for a specific global's value by key
final globalValueByKeyProvider = Provider.family<AsyncValue<String?>, String>((ref, key) {
  return ref.watch(globalByKeyProvider(key)).whenData(
    (global) => global?.value,
  );
});

class GlobalsNotifier extends StateNotifier<AsyncValue<List<Globals>>> {
  final GlobalsRepository _repository;

  GlobalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load initial globals
    loadGlobals();
  }

  Future<void> loadGlobals() async {
    try {
      state = const AsyncValue.loading();
      final globals = await _repository.listGlobals();
      state = AsyncValue.data(globals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      LogService.instance.error('Error loading globals: $error');
    }
  }

  Future<void> createGlobal({
    required String key,
    required String value,
    required String description,
  }) async {
    try {
      await _repository.createGlobal(
        key: key,
        value: value,
        description: description,
      );
      await loadGlobals();
    } catch (error) {
      LogService.instance.error('Error creating global: $error');
      rethrow;
    }
  }

  Future<void> updateGlobal(String documentId, String value) async {
    try {
      await _repository.updateGlobal(documentId, value);
      await loadGlobals();
    } catch (error) {
      LogService.instance.error('Error updating global: $error');
      rethrow;
    }
  }

  Future<void> deleteGlobal(String documentId) async {
    try {
      await _repository.deleteGlobal(documentId);
      await loadGlobals();
    } catch (error) {
      LogService.instance.error('Error deleting global: $error');
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

