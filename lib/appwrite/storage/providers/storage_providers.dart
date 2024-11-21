// lib/appwrite/storage/providers/storage_providers.dart
import 'dart:typed_data';
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
      final file = await _repository.uploadFile(
        bucket: bucket,
        fileName: fileName,
        fileBytes: bytes,
      );
      
      state = await state.whenData((files) => [...files, file]);
      return file;
    } catch (error) {
      throw error;
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _repository.deleteFile(
        bucket: bucket,
        fileId: fileId,
      );
      
      state = await state.whenData((files) => 
        files.where((file) => file.id != fileId).toList()
      );
    } catch (error) {
      throw error;
    }
  }

  Future<Uint8List> downloadFile(String fileId) async {
    return await _repository.downloadFile(
      bucket: bucket,
      fileId: fileId,
    );
  }

  Future<String> getFilePreviewUrl(String fileId, {int? width, int? height}) async {
    return await _repository.getFilePreviewUrl(
      bucket: bucket,
      fileId: fileId,
      width: width,
      height: height,
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