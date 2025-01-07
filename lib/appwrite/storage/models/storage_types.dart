// lib/appwrite/storage/models/storage_types.dart
enum StorageBucket {
  photos,
  lessons;

  String get id {
    switch (this) {
      case StorageBucket.photos:
        return 'photojam-bucket-photos';
      case StorageBucket.lessons:
        return 'photojam-bucket-lessons';
    }
  }

  List<String> get allowedExtensions {
    switch (this) {
      case StorageBucket.photos:
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      case StorageBucket.lessons:
        return ['.pdf', '.doc', '.docx', '.txt', '.md', '.jpg', '.jpeg', '.png', '.gif', '.webp'];
    }
  }

  int get maxFileSize {
    switch (this) {
      case StorageBucket.photos:
        return 10 * 1024 * 1024; // 10MB
      case StorageBucket.lessons:
        return 50 * 1024 * 1024; // 50MB
    }
  }

  String get bucketName {
    switch (this) {
      case StorageBucket.photos:
        return 'Photos';
      case StorageBucket.lessons:
        return 'Lessons';
    }
  }
}