import 'package:appwrite/models.dart';

class Submission {
  final String id;
  final String userId;
  final DateTime dateCreation;
  final List<String> photos;
  final String jamId;
  final String? comment;
  final DateTime dateUpdated;

  Submission({
    required this.id,
    required this.userId,
    required this.dateCreation,
    required this.photos,
    required this.jamId,
    this.comment,
    required this.dateUpdated,
  });

  factory Submission.fromDocument(Document doc) {
    return Submission(
      id: doc.$id,
      userId: doc.data['user_id'],
      dateCreation: DateTime.parse(doc.data['date_creation']),
      photos: List<String>.from(doc.data['photos'] ?? []),
      jamId: doc.data['jam']['\$id'],
      comment: doc.data['comment'],
      dateUpdated: DateTime.parse(doc.data['date_updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'date_creation': dateCreation.toIso8601String(),
    'photos': photos,
    'jam': jamId,
    'comment': comment,
    'date_updated': dateUpdated.toIso8601String(),
  };
}