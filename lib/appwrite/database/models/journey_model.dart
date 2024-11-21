import 'package:appwrite/models.dart';

class Journey {
  final String id;
  final String title;
  final List<String> participantIds;
  final bool isActive;
  final List<String> lessonIds;
  final DateTime dateCreation;
  final DateTime dateUpdated;

  Journey({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.isActive,
    required this.lessonIds,
    required this.dateCreation,
    required this.dateUpdated,
  });

  factory Journey.fromDocument(Document doc) {
    return Journey(
      id: doc.$id,
      title: doc.data['title'],
      participantIds: List<String>.from(doc.data['participant_ids'] ?? []),
      isActive: doc.data['is_active'],
      lessonIds: List<String>.from(doc.data['lesson']?.map((l) => l['\$id']) ?? []),
      dateCreation: DateTime.parse(doc.data['date_creation']),
      dateUpdated: DateTime.parse(doc.data['date_updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'participant_ids': participantIds,
    'is_active': isActive,
    'lesson': lessonIds,
    'date_creation': dateCreation.toIso8601String(),
    'date_updated': dateUpdated.toIso8601String(),
  };
}

