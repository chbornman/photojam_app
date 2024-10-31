import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class StorageAPI {
  final Client client;
  final Storage storage;

  StorageAPI(this.client) : storage = Storage(client);

  ////////////// Photos API /////////////
  Future<Uint8List?> fetchAuthenticatedImage(
      String imageUrl, String authToken) async {
    try {
      print("Fetching image from: $imageUrl");

      final response = await http.get(
        Uri.parse(Uri.encodeFull(imageUrl)), // Encode URL for compatibility
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-Appwrite-Project': APPWRITE_PROJECT_ID,
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print(
            'Failed to load image. Status code: ${response.statusCode}, Reason: ${response.reasonPhrase}');
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error fetching authenticated image: $e');
      return null;
    }
  }

  // Simplified getPhotoUrl without appending /v1
  Future<String> getPhotoUrl(String fileId) async {
    final endpoint = client.endPoint; // Base endpoint from client
    print("Appwrite endpoint: $endpoint"); // Print endpoint for debugging

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

  /// Deletes a photo by its file ID
  Future<void> deletePhoto(String fileId) async {
    try {
      await storage.deleteFile(
        bucketId: BUCKET_PHOTOS_ID,
        fileId: fileId,
      );
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  /// Fetches the last modified date of a file
  Future<DateTime?> getFileLastModified(String fileId) async {
    try {
      final file = await storage.getFile(
        bucketId: BUCKET_PHOTOS_ID,
        fileId: fileId,
      );
      return DateTime.parse(file.$updatedAt); // Parse updated timestamp
    } catch (e) {
      print('Error fetching last modified date: $e');
      return null; // Return null if the date cannot be retrieved
    }
  }

  ////////////// Lessons API /////////////

/// Uploads a lesson (markdown file) and returns the URL to access the file.
Future<String> uploadLesson(Uint8List data, String fileName) async {
  try {
    final result = await storage.createFile(
      bucketId: BUCKET_LESSONS_ID,
      fileId: 'unique()', // Generates a unique ID
      file: InputFile(bytes: data, filename: fileName),
    );

    // Construct the URL for the uploaded file
    final fileUrl = "$APPWRITE_ENDPOINT_ID/v1/storage/buckets/$BUCKET_LESSONS_ID/files/${result.$id}/view?project=$APPWRITE_PROJECT_ID";

    return fileUrl;
  } catch (e) {
    print('Error uploading lesson: $e');
    rethrow;
  }
}

  /// Retrieves a lesson (markdown file) directly by its URL.
  Future<Uint8List> getLessonByURL(String fileUrl) async {
    try {
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