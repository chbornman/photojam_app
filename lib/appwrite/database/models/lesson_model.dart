// lesson_model.dart
import 'package:appwrite/models.dart';

class Lesson {
  final String id;
  final String title;
  final DateTime dateCreation;
  final DateTime dateUpdated;
  final String contentFileId;
  final bool isActive;
  final int version;
  final String? journeyId;
  final String? jamId;
  final List<String> imagePaths;

  Lesson({
    required this.id,
    required this.title,
    required this.dateCreation,
    required this.dateUpdated,
    required this.contentFileId,
    required this.isActive,
    required this.version,
    this.journeyId,
    this.jamId,
    this.imagePaths = const [], // Default to empty list
  });

  factory Lesson.fromDocument(Document doc) {
    return Lesson(
      id: doc.$id,
      title: doc.data['title'],
      dateCreation: DateTime.parse(doc.data['date_creation']),
      dateUpdated: DateTime.parse(doc.data['date_updated']),
      contentFileId: doc.data['contentFileId'], // Updated to use file ID
      isActive: doc.data['is_active'],
      version: doc.data['version'],
      journeyId: doc.data['journey']?['\$id'],
      jamId: doc.data['jam']?['\$id'],
      imagePaths: List<String>.from(doc.data['image_paths'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'date_creation': dateCreation.toIso8601String(),
    'date_updated': dateUpdated.toIso8601String(),
    'content_file_id': contentFileId,
    'is_active': isActive,
    'version': version,
    'journey': journeyId != null ? {'\$id': journeyId} : null,
    'jam': jamId != null ? {'\$id': jamId} : null,
    'image_paths': imagePaths,
  };
}