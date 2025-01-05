import 'dart:io' as io;
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/storage/repositories/storage_repository.dart';
import 'package:photojam_app/appwrite/storage/models/storage_types.dart';
import 'package:photojam_app/core/services/log_service.dart';

class PhotoUploadService {
  final StorageRepository _storageRepository;
  static const int maxPhotoSize = 50 * 1024 * 1024;

  PhotoUploadService(this._storageRepository);

  Future<List<String>> uploadPhotos({
    required List<io.File?> photos,
    required String jamName,
    required String username,
    Submission? existingSubmission,
  }) async {
    List<String> fileIds = [];

    try {
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        if (photo != null) {
          final fileName = _formatFileName(i, jamName, username);
          LogService.instance.info('Uploading photo $fileName');

          // Delete existing photo if updating
          if (existingSubmission != null && i < existingSubmission.photos.length) {
            try {
              final oldFileId = existingSubmission.photos[i];
              await _storageRepository.deleteFile(
                bucket: StorageBucket.photos,
                fileId: oldFileId,
              );
              LogService.instance.info('Deleted existing photo: $oldFileId');
            } catch (e) {
              LogService.instance.error('Error deleting existing photo: $e');
            }
          }

          // Upload new photo
          final fileBytes = await photo.readAsBytes();
          final storageFile = await _storageRepository.uploadFile(
            bucket: StorageBucket.photos,
            fileName: fileName,
            fileBytes: fileBytes,
          );

          fileIds.add(storageFile.id);
          LogService.instance.info('Uploaded photo: $fileName with ID: ${storageFile.id}');
        }
      }

      LogService.instance.info('Successfully uploaded ${fileIds.length} photos: $fileIds');
      return fileIds;
    } catch (e) {
      LogService.instance.error('Error in uploadPhotos: $e');
      rethrow;
    }
  }


  String _formatFileName(int index, String jamName, String username) {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final sanitizedJamName = jamName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${sanitizedJamName}_${date}_${username}_photo${index + 1}.jpg';
  }
}