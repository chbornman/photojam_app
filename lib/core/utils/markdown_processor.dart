import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class MarkdownProcessor {
  static final RegExp _imagePattern = RegExp(r'!\[(.*?)\]\((.*?)\)');
  static final RegExp _imageUrlPattern =
      RegExp(r'https?://\S+\.(jpg|jpeg|png|gif|webp)', caseSensitive: false);

  final StorageNotifier _storage;
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionLessons;

  MarkdownProcessor(this._storage, this._db);

  /// Process the markdown, uploading images and the processed .md itself,
  /// then create a database document. 
  /// This method now includes all logic previously found in the repository.
  Future<void> processMarkdown({
    required String markdownContent,
    required String lessonId,
    required Map<String, Uint8List> otherFiles,
    required String mdFileName,
    required String? journeyId,
    required String? jamId,
  }) async {
    LogService.instance.info('Processing markdown content for lesson: $lessonId');

    String processedContent = markdownContent;

    final uploadedImageIds = <String>[];
    // Find image references: ![alt](path)
    final matches = _imagePattern.allMatches(markdownContent);

    for (final match in matches) {
      final altText = match.group(1) ?? '';
      final initImagePath = match.group(2) ?? '';

      // If it's a web image, leave as-is
      if (_imageUrlPattern.hasMatch(initImagePath)) {
        LogService.instance.info('Skipping web image: $initImagePath');
        continue;
      }

      // Otherwise, treat as a local image, get its basename
      final imagePath = path.basename(initImagePath);
      final sanitizedAltText = _sanitizeFilename(altText);
      final newFilename = '${lessonId}_${sanitizedAltText}_$imagePath';

      // 1) Upload the matching file from `otherFiles` to storage.
      if (!otherFiles.containsKey(imagePath)) {
        LogService.instance.info('File not found in otherFiles: $imagePath');
        continue;
      }

      // Actually upload to Appwrite
      final uploadResult = await _storage.uploadFile(
        newFilename,
        otherFiles[imagePath]!,
      );
      final storageId = uploadResult.id;
      uploadedImageIds.add(storageId);

      // 2) Replace the local path with /imageBuilder/<storageId>
      final placeholder = '![${altText}](/imageBuilder/$storageId)';
      processedContent = processedContent.replaceAll(match.group(0)!, placeholder);
      final linkPlaceholder = '/imageBuilder/$storageId';
      processedContent = processedContent.replaceAll(initImagePath, linkPlaceholder);

      LogService.instance.info('Uploaded image: $storageId');
    }

    // 3) Now that processedContent is updated, upload the markdown file itself
    final file = await _storage.uploadFile(
      mdFileName,
      utf8.encode(processedContent),
    );
    LogService.instance.info("Markdown file uploaded: ${file.id}");

    // 4) Create a document in the DB
    final now = DateTime.now().toIso8601String();
    final documentData = {
      'title': mdFileName,
      'contentFileId': file.id,
      'version': 1,
      'is_active': true,
      'journey': journeyId != null ? {'\$id': journeyId} : null,
      'jam': jamId != null ? {'\$id': jamId} : null,
      'date_creation': now,
      'date_updated': now,
      'image_ids': uploadedImageIds,
    };

    final doc = await _db.createDocument(
      collectionId,
      documentData,
    );
    LogService.instance.info("Created lesson document: ${doc.$id}");
  }

  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
