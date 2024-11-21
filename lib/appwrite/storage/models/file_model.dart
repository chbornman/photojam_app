// lib/appwrite/storage/models/file_model.dart
import 'package:appwrite/models.dart';

class StorageFile {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final DateTime dateCreated;
  final String? signature;

  StorageFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.dateCreated,
    this.signature,
  });

  factory StorageFile.fromFile(File file) {
    return StorageFile(
      id: file.$id,
      name: file.name,
      sizeBytes: file.sizeOriginal,
      mimeType: file.mimeType,
      dateCreated: DateTime.parse(file.$createdAt),
      signature: file.signature,
    );
  }
}
