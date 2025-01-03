// lib/core/services/markdown_processor.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:photojam_app/core/services/log_service.dart';

class MarkdownProcessor {
  static final RegExp _imagePattern = RegExp(r'!\[(.*?)\]\((.*?)\)');
  static final RegExp _imageUrlPattern = RegExp(r'https?://\S+\.(jpg|jpeg|png|gif|webp)', caseSensitive: false);

  Future<ProcessedMarkdown> processMarkdown({
    required String markdownContent,
    required String lessonId,
  }) async {
    LogService.instance.info('Processing markdown content for lesson: $lessonId');
    
    final Map<String, Uint8List> imageFiles = {};
    String processedContent = markdownContent;
    
    final matches = _imagePattern.allMatches(markdownContent);
    
    for (final match in matches) {
      final altText = match.group(1) ?? '';
      final imageUrl = match.group(2) ?? '';
      
      if (_imageUrlPattern.hasMatch(imageUrl)) {
        try {
          LogService.instance.info('Downloading image from: $imageUrl');
          
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final originalFilename = path.basename(imageUrl);
            final extension = path.extension(originalFilename);
            final sanitizedAltText = _sanitizeFilename(altText);
            final newFilename = '${lessonId}_${sanitizedAltText}_image${extension}';
            
            imageFiles[newFilename] = response.bodyBytes;
            
            // Update path to reference same bucket
            final placeholder = '![${altText}](/lessons/${newFilename})';
            processedContent = processedContent.replaceAll(match.group(0)!, placeholder);
            
            LogService.instance.info('Processed image: $newFilename');
          }
        } catch (e) {
          LogService.instance.error('Error processing image $imageUrl: $e');
        }
      }
    }
    
    return ProcessedMarkdown(
      content: processedContent,
      images: imageFiles,
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