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
  final data = doc.data;

  return Jam(
    id: doc.$id,
    submissionIds: data['submission'] is List
        ? List<String>.from(data['submission'].map((s) => s['\$id']))
        : [],
    title: data['title'] ?? '',
    eventDatetime: DateTime.parse(data['event_datetime'] ?? DateTime.now().toIso8601String()),
    zoomLink: data['zoom_link'] ?? '',
    facilitatorId: data['facilitator_id'],
    selectedPhotos: data['selected_photos'] is List
        ? List<String>.from(data['selected_photos'])
        : [],
    lessonId: data['lesson'] is Map
        ? data['lesson']['\$id']
        : data['lesson'] as String?,
    dateCreated: DateTime.parse(data['date_created'] ?? DateTime.now().toIso8601String()),
    dateUpdated: DateTime.parse(data['date_updated'] ?? DateTime.now().toIso8601String()),
    isActive: data['is_active'] ?? false,
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