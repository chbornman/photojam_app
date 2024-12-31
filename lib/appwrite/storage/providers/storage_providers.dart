import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_config.dart';
import 'package:photojam_app/appwrite/appwrite_storage_repository.dart';
import '../models/storage_types.dart';
import '../models/file_model.dart';
import '../repositories/storage_repository.dart';

// Base repository provider remains the same
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final storage = ref.watch(appwriteStorageProvider);
  return AppwriteStorageRepository(storage);
});

// Updated providers using StorageBucket enum
final photoStorageProvider = StateNotifierProvider<StorageNotifier, AsyncValue<List<StorageFile>>>((ref) {
  final storageRepository = ref.watch(storageRepositoryProvider);
  return StorageNotifier(storageRepository, bucket: StorageBucket.photos);
});

final lessonStorageProvider = StateNotifierProvider<StorageNotifier, AsyncValue<List<StorageFile>>>((ref) {
  final storageRepository = ref.watch(storageRepositoryProvider);
  return StorageNotifier(storageRepository, bucket: StorageBucket.lessons);
});

class StorageNotifier extends StateNotifier<AsyncValue<List<StorageFile>>> {
  final StorageRepository _repository;
  final StorageBucket bucket;

  StorageNotifier(this._repository, {required this.bucket}) 
      : super(const AsyncValue.loading()) {
    loadFiles();
  }

  // Expose the underlying Storage instance
  Storage get storage => _repository.storage;

  // New method to get max file size based on bucket type
  int getMaxFileSizeForBucket() {
    switch (bucket) {
      case StorageBucket.photos:
        return 50 * 1024 * 1024; // 50MB in bytes
      case StorageBucket.lessons:
        return 20 * 1024 * 1024; // 20MB in bytes
    }
  }

  Future<void> loadFiles() async {
    try {
      state = const AsyncValue.loading();
      final files = await _repository.listFiles(bucket: bucket);
      state = AsyncValue.data(files);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<StorageFile> uploadFile(String fileName, Uint8List bytes) async {
    try {
      // Add file size validation
      if (bytes.length > getMaxFileSizeForBucket()) {
        throw Exception('File size exceeds maximum allowed size for this bucket type');
      }

      final file = await _repository.uploadFile(
        bucket: bucket,
        fileName: fileName,
        fileBytes: bytes,
      );
      
      state = state.whenData((files) => [...files, file]);
      return file;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _repository.deleteFile(
        bucket: bucket,
        fileId: fileId,
      );
      
      state = state.whenData((files) => 
        files.where((file) => file.id != fileId).toList()
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<Uint8List> downloadFile(String fileId) async {
    return await _repository.downloadFile(
      bucket: bucket,
      fileId: fileId,
    );
  }
}

// Optional: Helper provider to get storage notifier by bucket type
final storageNotifierProvider = Provider.family<StorageNotifier, StorageBucket>((ref, bucket) {
  switch (bucket) {
    case StorageBucket.photos:
      return ref.watch(photoStorageProvider.notifier);
    case StorageBucket.lessons:
      return ref.watch(lessonStorageProvider.notifier);
  }
});