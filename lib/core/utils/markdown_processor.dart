import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:photojam_app/core/services/log_service.dart';

class MarkdownProcessor {
  static final RegExp _imagePattern = RegExp(r'!\[(.*?)\]\((.*?)\)');
  static final RegExp _imageUrlPattern =
      RegExp(r'https?://\S+\.(jpg|jpeg|png|gif|webp)', caseSensitive: false);

  Future<ProcessedMarkdown> processMarkdown({
    required String markdownContent,
    required String lessonId,
    required Map<String, Uint8List> otherFiles,
  }) async {
    LogService.instance
        .info('Processing markdown content for lesson: $lessonId');

    String processedContent = markdownContent;
    final Map<String, Uint8List> images = {};

    final matches = _imagePattern.allMatches(markdownContent);

    for (final match in matches) {
      final altText = match.group(1) ?? '';
      final initimagePath = match.group(2) ?? '';

      // If it's a web image, leave it as-is.
      if (_imageUrlPattern.hasMatch(initimagePath)) {
        LogService.instance.info('Skipping web image; not modifying: $initimagePath');
        continue;
      }

      final imagePath = path.basename(match.group(2) ?? '');

      // Otherwise, treat it as a local image.
      final originalFilename = imagePath;
      final sanitizedAltText = _sanitizeFilename(altText);
      final newFilename = '${lessonId}_${sanitizedAltText}_$originalFilename';

      // Update the Markdown reference to point to /lessons/newFilename
      final placeholder = '![${altText}](/lessons/$newFilename)';
      processedContent = processedContent.replaceAll(match.group(0)!, placeholder);

      // Use otherFiles to get the image bytes
      if (!otherFiles.containsKey(imagePath)) {
        LogService.instance.info('File not found in otherFiles: $imagePath');
      } else {
        images[newFilename] = otherFiles[imagePath]!;
        LogService.instance.info('Processed local image: $newFilename');
      }
    }

    return ProcessedMarkdown(
      content: processedContent,
      images: images,
    );
  }

  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}

class ProcessedMarkdown {
  final String content;
  final Map<String, Uint8List> images;

  ProcessedMarkdown({
    required this.content,
    required this.images,
  });
}
