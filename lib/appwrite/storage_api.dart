import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'dart:typed_data';

class StorageAPI {
  final Client client;
  final Storage storage;

  StorageAPI(this.client) : storage = Storage(client);

  ////////////// Photos API /////////////

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

  /// Retrieves a lesson (markdown file) by its storage item ID.
  Future<Uint8List> getLesson(String fileId) async {
    try {
      final result = await storage.getFileDownload(
        bucketId: BUCKET_LESSONS_ID,
        fileId: fileId,
      );
      return result;
    } catch (e) {
      print('Error retrieving lesson: $e');
      rethrow;
    }
  }
}
