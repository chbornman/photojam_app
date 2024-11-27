import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import '../models/file_model.dart';
import '../models/storage_types.dart';

abstract class StorageRepository {
  Storage get storage;  // Add this abstract getter

  int getMaxFileSizeForBucket(StorageBucket bucket);

  Future<StorageFile> uploadFile({
    required StorageBucket bucket,
    required String fileName,
    required Uint8List fileBytes,
  });
  
  Future<Uint8List> downloadFile({
    required StorageBucket bucket,
    required String fileId,
  });
  
  Future<void> deleteFile({
    required StorageBucket bucket,
    required String fileId,
  });
  
  Future<List<StorageFile>> listFiles({
    required StorageBucket bucket,
    List<String>? queries,
  });
  
  Future<String> getFilePreviewUrl({
    required StorageBucket bucket,
    required String fileId,
    required int width,
    required int height,
  });
}

/// Extension to provide default implementation for max file sizes
extension StorageRepositoryDefaults on StorageRepository {
  int getMaxFileSizeForBucket(StorageBucket bucket) {
    switch (bucket) {
      case StorageBucket.photos:
        return 50 * 1024 * 1024; // 50MB in bytes
      case StorageBucket.lessons:
        return 20 * 1024 * 1024; // 20MB in bytes
    }
  }
}