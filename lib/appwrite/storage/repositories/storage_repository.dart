// lib/appwrite/storage/repositories/storage_repository.dart
import 'dart:typed_data';
import '../models/file_model.dart';
import '../models/storage_types.dart';

abstract class StorageRepository {
  Future<StorageFile> uploadFile({
    required StorageBucket bucket,
    required String fileName,
    required Uint8List fileBytes,
    List<String>? permissions,
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
    int? width,
    int? height,
  });
}
