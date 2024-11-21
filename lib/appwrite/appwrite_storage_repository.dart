import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/storage/models/file_model.dart';
import 'package:photojam_app/appwrite/storage/models/storage_types.dart';
import 'package:photojam_app/appwrite/storage/repositories/storage_repository.dart';


class AppwriteStorageRepository with StorageHelper implements StorageRepository {
  final Storage _storage;

  AppwriteStorageRepository(this._storage);

  @override
  Future<StorageFile> uploadFile({
    required StorageBucket bucket,
    required String fileName,
    required Uint8List fileBytes,
    List<String>? permissions,
  }) async {
    if (!isValidFileForBucket(bucket, fileName)) {
      throw Exception('Invalid file type for this bucket');
    }

    try {
      final file = await _storage.createFile(
        bucketId: bucket.id,
        fileId: ID.unique(),
        file: InputFile.fromBytes(bytes: fileBytes, filename: fileName),
        permissions: permissions,
      );
      return StorageFile.fromFile(file);
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  @override
  Future<Uint8List> downloadFile({
    required StorageBucket bucket,
    required String fileId,
  }) async {
    try {
      return await _storage.getFileDownload(
        bucketId: bucket.id,
        fileId: fileId,
      );
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  @override
  Future<void> deleteFile({
    required StorageBucket bucket,
    required String fileId,
  }) async {
    try {
      await _storage.deleteFile(
        bucketId: bucket.id,
        fileId: fileId,
      );
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  @override
  Future<List<StorageFile>> listFiles({
    required StorageBucket bucket,
    List<String>? queries,
  }) async {
    try {
      final files = await _storage.listFiles(
        bucketId: bucket.id,
        queries: queries,
      );
      return files.files.map((file) => StorageFile.fromFile(file)).toList();
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  @override
  Future<String> getFilePreviewUrl({
    required StorageBucket bucket,
    required String fileId,
    int? width,
    int? height,
  }) async {  // Made async and added await
    try {
      final url = await _storage.getFilePreview(
        bucketId: bucket.id,
        fileId: fileId,
        width: width,
        height: height,
      );
      return url.toString();
    } catch (e) {
      throw _handleStorageError(e);
    }
  }

  Exception _handleStorageError(dynamic e) {
    if (e is AppwriteException) {
      return Exception(e.message);
    }
    return Exception('An unexpected error occurred');
  }
}

// Add StorageHelper mixin to the same file or move to storage_helper.dart
mixin StorageHelper {
  bool isValidFileForBucket(StorageBucket bucket, String fileName) {
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return bucket.allowedExtensions.contains(extension);
  }

  String getFileExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return '';
    return fileName.substring(lastDotIndex).toLowerCase();
  }

  bool isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.contains(getFileExtension(fileName));
  }

  bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == '.pdf';
  }

  int getMaxFileSizeForBucket(StorageBucket bucket) {
    switch (bucket) {
      case StorageBucket.photos:
        return 10 * 1024 * 1024; // 10MB for photos
      case StorageBucket.lessons:
        return 50 * 1024 * 1024; // 50MB for lessons
    }
  }
}