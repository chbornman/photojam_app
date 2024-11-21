import 'package:appwrite/models.dart';

class Jam {
  final String id;
  final List<String> submissionIds;
  final String title;
  final DateTime eventDatetime;
  final String zoomLink;
  final String? facilitatorId;
  final List<String> selectedPhotos;
  final String? lessonId;
  final DateTime dateCreated;
  final DateTime dateUpdated;
  final bool isActive;

  Jam({
    required this.id,
    required this.submissionIds,
    required this.title,
    required this.eventDatetime,
    required this.zoomLink,
    this.facilitatorId,
    this.selectedPhotos = const [],
    this.lessonId,
    required this.dateCreated,
    required this.dateUpdated,
    required this.isActive,
  });

  factory Jam.fromDocument(Document doc) {
    return Jam(
      id: doc.$id,
      submissionIds: List<String>.from(doc.data['submission'] ?? []),
      title: doc.data['title'],
      eventDatetime: DateTime.parse(doc.data['event_datetime']),
      zoomLink: doc.data['zoom_link'],
      facilitatorId: doc.data['facilitator_id'],
      selectedPhotos: List<String>.from(doc.data['selected_photos'] ?? []),
      lessonId: doc.data['lesson']?['\$id'],
      dateCreated: DateTime.parse(doc.data['date_created']),
      dateUpdated: DateTime.parse(doc.data['date_updated']),
      isActive: doc.data['is_active'],
    );
  }

  Map<String, dynamic> toJson() => {
    'submission': submissionIds,
    'title': title,
    'event_datetime': eventDatetime.toIso8601String(),
    'zoom_link': zoomLink,
    'facilitator_id': facilitatorId,
    'selected_photos': selectedPhotos,
    'lesson': lessonId,
    'date_created': dateCreated.toIso8601String(),
    'date_updated': dateUpdated.toIso8601String(),
    'is_active': isActive,
  };
}