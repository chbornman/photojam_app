import 'package:appwrite/models.dart';

class Globals {
  final String id;
  final String key;
  final String value;
  final String description;
  final DateTime dateUpdated;

  Globals({
    required this.id,
    required this.key,
    required this.value,
    required this.description,
    required this.dateUpdated,
  });

  // Factory constructor to create a Globals object from a document
  factory Globals.fromDocument(Document doc) {
    return Globals(
      id: doc.$id,
      key: doc.data['key'],
      value: doc.data['value'],
      description: doc.data['description'],
      dateUpdated: DateTime.parse(doc.data['date_updated']),
    );
  }

  // Method to convert a Globals object to a JSON representation for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'date_updated': dateUpdated.toIso8601String(),
    };
  }
}
