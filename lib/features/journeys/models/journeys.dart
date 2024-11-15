// lib/features/journeys/models/journey.dart
class Journey {
  final String id;
  final String title;
  final List<String> lessons;

  Journey({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory Journey.fromMap(Map<String, dynamic> map) {
    return Journey(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Journey',
      lessons: List<String>.from(map['lessons'] ?? []),
    );
  }
}
