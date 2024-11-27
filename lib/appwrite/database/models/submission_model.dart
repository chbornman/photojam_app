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

  Document toDocument() {
    return Document(
      $id: id,
      data: toJson(),  // Use toJson() to maintain consistency
      $collectionId: 'photojam-collection-submission', // Updated to match actual collection ID
      $databaseId: 'default',
      $createdAt: dateCreation.toIso8601String(),
      $updatedAt: dateUpdated.toIso8601String(),
      $permissions: []
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'date_creation': dateCreation.toIso8601String(),
    'photos': photos,
    'jam': {'\$id': jamId},  // Updated to match the structure expected by Appwrite
    'comment': comment ?? '',  // Ensure comment is never null
    'date_updated': dateUpdated.toIso8601String(),
  };

    Submission copyWith({
    String? id,
    String? userId,
    DateTime? dateCreation,
    List<String>? photos,
    String? jamId,
    String? comment,
    DateTime? dateUpdated,
  }) {
    return Submission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateCreation: dateCreation ?? this.dateCreation,
      photos: photos ?? this.photos,
      jamId: jamId ?? this.jamId,
      comment: comment ?? this.comment,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }

}