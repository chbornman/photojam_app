// lesson_model.dart
import 'package:appwrite/models.dart';

class Lesson {
  final String id;
  final String title;
  final DateTime dateCreation;
  final DateTime dateUpdated;
  final Uri content;  // Changed from String to Uri
  final bool isActive;
  final int version;
  final String? journeyId;
  final String? jamId;

  Lesson({
    required this.id,
    required this.title,
    required this.dateCreation,
    required this.dateUpdated,
    required this.content,
    required this.isActive,
    required this.version,
    this.journeyId,
    this.jamId,
  });

  factory Lesson.fromDocument(Document doc) {
    return Lesson(
      id: doc.$id,
      title: doc.data['title'],
      dateCreation: DateTime.parse(doc.data['date_creation']),
      dateUpdated: DateTime.parse(doc.data['date_updated']),
      content: Uri.parse(doc.data['content']), // Parse string to Uri
      isActive: doc.data['is_active'],
      version: doc.data['version'],
      journeyId: doc.data['journey']?['\$id'],
      jamId: doc.data['jam']?['\$id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'date_creation': dateCreation.toIso8601String(),
    'date_updated': dateUpdated.toIso8601String(),
    'content': content.toString(), // Convert Uri to string
    'is_active': isActive,
    'version': version,
    'journey': journeyId != null ? {'\$id': journeyId} : null,
    'jam': jamId != null ? {'\$id': jamId} : null,
  };
}