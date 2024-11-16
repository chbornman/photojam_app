// lib/features/jams/services/photo_upload_service.dart
import 'dart:io' as io;
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/core/services/log_service.dart';

class PhotoUploadService {
  final StorageAPI _storageApi;
  static const int maxPhotoSize = 50 * 1024 * 1024; // 50MB

  PhotoUploadService(this._storageApi);

  Future<List<String>> uploadPhotos({
    required List<io.File?> photos,
    required String jamName,
    required String username,
    Document? existingSubmission,
  }) async {
    List<String> photoUrls = [];

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo != null) {
        final fileName = _formatFileName(i, jamName, username);
        
        if (existingSubmission != null) {
          await _deleteExistingPhoto(existingSubmission, i);
        }

        final photoId = await _storageApi.uploadPhoto(
          await photo.readAsBytes(),
          fileName,
        );
        final photoUrl = await _storageApi.getPhotoUrl(photoId);
        photoUrls.add(photoUrl);
      }
    }

    return photoUrls;
  }

  Future<void> deleteSubmissionPhotos(Document submission) async {
    final photos = List<String>.from(submission.data['photos'] as List? ?? []);
    
    for (String url in photos) {
      try {
        final fileId = _extractFileIdFromUrl(url);
        await _storageApi.deletePhoto(fileId);
        LogService.instance.info("Deleted photo with file ID: $fileId");
      } catch (e) {
        LogService.instance.error("Error deleting photo: $e");
      }
    }
  }

  String _formatFileName(int index, String jamName, String username) {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final sanitizedJamName = jamName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return "${sanitizedJamName}_${date}_${username}_photo${index + 1}.jpg";
  }

  Future<void> _deleteExistingPhoto(Document submission, int index) async {
    final photos = List<String>.from(submission.data['photos'] as List? ?? []);
    if (index < photos.length) {
      final oldUrl = photos[index];
      final fileId = _extractFileIdFromUrl(oldUrl);
      await _storageApi.deletePhoto(fileId);
    }
  }

  String _extractFileIdFromUrl(String url) {
    final regex = RegExp(r'/files/([^/]+)/view');
    final match = regex.firstMatch(url);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    throw Exception('Invalid URL format: Unable to extract file ID');
  }

  bool isPhotoSizeValid(io.File photo) {
    return photo.lengthSync() <= maxPhotoSize;
  }
}