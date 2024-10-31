import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class StorageAPI {
  final Client client;
  final Storage storage;

  StorageAPI(this.client) : storage = Storage(client);

  ////////////// Photos API /////////////

  // Simplified getPhotoUrl without appending /v1
  Future<String> getPhotoUrl(String fileId) async {
    final endpoint = client.endPoint;  // Base endpoint from client
    print("Appwrite endpoint: $endpoint");  // Print endpoint for debugging

    // Construct the URL without manually adding /v1
    return "$endpoint/storage/buckets/$BUCKET_PHOTOS_ID/files/$fileId/view";
  }
  /// Uploads a photo and returns the storage item ID.
  Future<String> uploadPhoto(Uint8List data, String fileName) async {
    try {
      final result = await storage.createFile(
        bucketId: BUCKET_PHOTOS_ID,
        fileId: 'unique()', // Generates a unique ID
        file: InputFile(bytes: data, filename: fileName),
      );
      return result.$id;
    } catch (e) {
      print('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Retrieves a photo by its storage item ID.
  Future<Uint8List> getPhoto(String fileId) async {
    try {
      final result = await storage.getFileDownload(
        bucketId: BUCKET_PHOTOS_ID,
        fileId: fileId,
      );
      return result;
    } catch (e) {
      print('Error retrieving photo: $e');
      rethrow;
    }
  }

  ////////////// Lessons API /////////////

  /// Uploads a lesson (markdown file) and returns the storage item ID.
  Future<String> uploadLesson(Uint8List data, String fileName) async {
    try {
      final result = await storage.createFile(
        bucketId: BUCKET_LESSONS_ID,
        fileId: 'unique()', // Generates a unique ID
        file: InputFile(bytes: data, filename: fileName),
      );
      return result.$id;
    } catch (e) {
      print('Error uploading lesson: $e');
      rethrow;
    }
  }

  /// Retrieves a lesson (markdown file) directly by its URL.
  // Direct URL retrieval using `http` package
  Future<Uint8List> getLessonByURL(String fileUrl) async {
    try {
      // Make a GET request directly to the provided URL
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes; // Return the file as Uint8List
      } else {
        throw Exception('Failed to load lesson from URL');
      }
    } catch (e) {
      print('Error retrieving lesson by URL: $e');
      rethrow;
    }
  }
}
