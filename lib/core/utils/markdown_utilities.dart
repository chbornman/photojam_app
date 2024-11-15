// markdown_utilities.dart
import 'dart:convert';
import 'dart:typed_data';

/// Extracts the title from markdown content by retrieving the first line
/// that starts with a '#'. If no such line is found, returns 'Untitled Lesson'.
String extractTitleFromMarkdown(Uint8List lessonData) {
  final content = utf8.decode(lessonData);
  final firstLine = content.split('\n').first.trim();
  return firstLine.startsWith('#')
      ? firstLine.replaceFirst('#', '').trim()
      : 'Untitled Lesson';
}