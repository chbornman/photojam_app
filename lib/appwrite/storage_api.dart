import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart'; // Import DatabaseAPI
import 'package:photojam_app/constants/constants.dart';

class StorageAPI {
  Client client = Client();
  late final Account account;
  late final Storage storage;
  final DatabaseAPI databaseApi = DatabaseAPI(); // Use DatabaseAPI instance
  final AuthAPI auth = AuthAPI();

  StorageAPI() {
    init();
  }

  init() {
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();
    account = Account(client);
    storage = Storage(client);
  }

  /// Uploads a photo for a specific jam. Returns the file ID on success.
  Future<String?> uploadPhoto(String jamId, String filePath) async {
    try {
      final response = await storage.createFile(
        bucketId: BUCKET_PHOTOS_ID, // Replace with your actual bucket ID
        fileId: 'unique()', // Generates a unique file ID
        file: InputFile(path: filePath),
      );

      // Store file ID in the jam document after successful upload
      await addPhotoToJam(jamId, response.$id);
      return response.$id;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Adds the uploaded photo's file ID to the jam document.
  Future<void> addPhotoToJam(String jamId, String fileId) async {
    try {
      // Fetch the list of jams to find the specific jam document
      final jams = await databaseApi.getJams();
      final jamDocument = jams.documents.firstWhere(
        (doc) => doc.$id == jamId,
        orElse: () => throw Exception('Jam not found'),
      );

      // Update the jam document with the new photo ID
      List<String> photoIds = List<String>.from(jamDocument.data['photoIds'] ?? []);
      if (photoIds.length < 3) {
        photoIds.add(fileId);
        await databaseApi.databases.updateDocument(
          databaseId: APPWRITE_DATABASE_ID,
          collectionId: COLLECTION_JAMS,
          documentId: jamId,
          data: {'photoIds': photoIds},
        );
      } else {
        print('Error: Maximum number of photos already uploaded for this jam.');
      }
    } catch (e) {
      print('Error adding photo to jam: $e');
    }
  }

  /// Downloads a photo from storage given its file ID.
  Future<void> downloadPhoto(String fileId, String destinationPath) async {
    try {
      await storage.getFileDownload(
        bucketId: BUCKET_PHOTOS_ID,
        fileId: fileId,
      ).then((response) {
        // Save file to destinationPath
        // Use a package like `dio` to handle saving the file locally.
        print('Photo downloaded successfully to $destinationPath');
      });
    } catch (e) {
      print('Error downloading photo: $e');
    }
  }

  /// Lists all photo file IDs associated with a specific jam.
  Future<List<String>?> listPhotosForJam(String jamId) async {
    try {
      final jams = await databaseApi.getJams();
      final jamDocument = jams.documents.firstWhere(
        (doc) => doc.$id == jamId,
        orElse: () => throw Exception('Jam not found'),
      );

      return List<String>.from(jamDocument.data['photoIds'] ?? []);
    } catch (e) {
      print('Error listing photos for jam: $e');
      return null;
    }
  }

  /// Uploads a lesson (markdown file) for a specific journey. Returns the file ID on success.
  Future<String?> uploadLesson(String journeyId, String filePath) async {
    try {
      final response = await storage.createFile(
        bucketId: BUCKET_LESSONS_ID, // Define a specific bucket for lessons
        fileId: 'unique()', // Generates a unique file ID
        file: InputFile(path: filePath),
      );

      // Store file ID in the journey document for future retrieval
      await addLessonToJourney(journeyId, response.$id);
      return response.$id;
    } catch (e) {
      print('Error uploading lesson: $e');
      return null;
    }
  }

  /// Adds the uploaded lesson's file ID to the journey document.
  Future<void> addLessonToJourney(String journeyId, String fileId) async {
    try {
      // Fetch the journey document to update with new lesson file ID
      final journeyDocument = await databaseApi.databases.getDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS, // Collection for journeys
        documentId: journeyId,
      );

      // Update the journey document with the new lesson file ID
      List<String> lessonIds = List<String>.from(journeyDocument.data['lessonIds'] ?? []);
      lessonIds.add(fileId);
      await databaseApi.databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
        data: {'lessonIds': lessonIds},
      );
    } catch (e) {
      print('Error adding lesson to journey: $e');
    }
  }

  /// Downloads a lesson from storage given its file ID.
  Future<void> downloadLesson(String fileId, String destinationPath) async {
    try {
      await storage.getFileDownload(
        bucketId: BUCKET_LESSONS_ID, // Use the specific lessons bucket ID
        fileId: fileId,
      ).then((response) {
        // Save file to destinationPath
        // Use a package like `dio` to handle saving the file locally.
        print('Lesson downloaded successfully to $destinationPath');
      });
    } catch (e) {
      print('Error downloading lesson: $e');
    }
  }
}