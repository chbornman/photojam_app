import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:photojam_app/log_service.dart';

class StorageAPI {
  final Client client;
  final Storage storage;

  StorageAPI(this.client) : storage = Storage(client);

  ////////////// Photos API /////////////
  Future<Uint8List?> fetchAuthenticatedImage(
      String imageUrl, String authToken) async {
    try {
      LogService.instance.info("Fetching image from: $imageUrl");

      final response = await http.get(
        Uri.parse(Uri.encodeFull(imageUrl)), // Encode URL for compatibility
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-Appwrite-Project': appwriteProjectId,
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        LogService.instance.info(
            'Failed to load image. Status code: ${response.statusCode}, Reason: ${response.reasonPhrase}');
        throw Exception('Failed to load image');
      }
    } catch (e) {
      LogService.instance.error("Error fetching image: $e");
      return null;
    }
  }

  Future<Uint8List?> processFile(String encodedPath) async {
    // Decode the encoded path to handle any special characters
    final imagePath = Uri.decodeFull(encodedPath);
    final file = File(imagePath);

    try {
      if (await file.exists()) {
        LogService.instance.info("File found at $imagePath, proceeding with upload.");
        return await file.readAsBytes(); // Or any other file operation
      } else {
        LogService.instance.info("File at $imagePath does not exist. Verify path or permissions.");
        return null; // Or handle this case as needed
      }
    } catch (e) {
      LogService.instance.error("Error reading file: $e");
      return null;
    }
  }

  // Simplified getPhotoUrl without appending /v1
  Future<String> getPhotoUrl(String fileId) async {
    final endpoint = client.endPoint; // Base endpoint from client
    LogService.instance.info("Appwrite endpoint: $endpoint"); // Print endpoint for debugging

    // Construct the URL without manually adding /v1
    return "$endpoint/storage/buckets/$bucketPhotosId/files/$fileId/view";
  }

  /// Uploads a photo and returns the storage item ID.
  Future<String> uploadPhoto(Uint8List data, String fileName) async {
    try {
      final result = await storage.createFile(
        bucketId: bucketPhotosId,
        fileId: 'unique()', // Generates a unique ID
        file: InputFile(bytes: data, filename: fileName),
      );
      return result.$id;
    } catch (e) {
      LogService.instance.error('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Retrieves a photo by its storage item ID.
  Future<Uint8List> getPhoto(String fileId) async {
    try {
      final result = await storage.getFileDownload(
        bucketId: bucketPhotosId,
        fileId: fileId,
      );
      return result;
    } catch (e) {
      LogService.instance.error('Error retrieving photo: $e');
      rethrow;
    }
  }

  /// Deletes a photo by its file ID
  Future<void> deletePhoto(String fileId) async {
    try {
      await storage.deleteFile(
        bucketId: bucketPhotosId,
        fileId: fileId,
      );
    } catch (e) {
      LogService.instance.error('Error deleting photo: $e');
    }
  }

  /// Fetches the last modified date of a file
  Future<DateTime?> getFileLastModified(String fileId) async {
    try {
      final file = await storage.getFile(
        bucketId: bucketPhotosId,
        fileId: fileId,
      );
      return DateTime.parse(file.$updatedAt); // Parse updated timestamp
    } catch (e) {
      LogService.instance.error('Error fetching last modified date: $e');
      return null; // Return null if the date cannot be retrieved
    }
  }

  ////////////// Lessons API /////////////

  /// Uploads a lesson (markdown file) and processes images in the markdown.
  /// Automatically replaces local image paths with URLs to the uploaded images.
  Future<String> uploadLesson(Uint8List markdownData, String fileName) async {
    try {
      // Step 1: Convert Markdown to string and find image paths
      String markdownContent = String.fromCharCodes(markdownData);
      final imageRegex =
          RegExp(r'!\[.*?\]\((.*?)\)'); // Matches image paths in markdown
      final matches = imageRegex.allMatches(markdownContent);

      // Step 2: Map to store local path to URL replacements
      Map<String, String> imagePathToUrl = {};

      // Step 3: Process each image found in the markdown
      for (var match in matches) {
        String imagePath = match.group(1)!; // Extract the image path

        // Filter to skip URLs and non-image files
        if (_isLocalImagePath(imagePath)) {
          // Step 3a: Download the image data
          try {
            Uint8List? imageData = await fetchLocalImageData('$appwriteEndpointId/storage/buckets/$bucketLessonsId/files/', imagePath);
            if (imageData != null) {
              // Step 3b: Upload the image to Appwrite
              String imageId = await _uploadLessonImage(imageData, imagePath);
              String imageUrl =
                  "$appwriteEndpointId/storage/buckets/$bucketLessonsId/files/$imageId/view?project=$appwriteProjectId";

              // Map the original image path to the new URL
              imagePathToUrl[imagePath] = imageUrl;
            } else {
              LogService.instance.info("Warning: Failed to fetch image data for $imagePath");
            }
          } catch (e) {
            LogService.instance.error("Error processing image '$imagePath': $e");
          }
        } else {
          LogService.instance.info("Skipping non-image or external URL: $imagePath");
        }
      }

      // Step 4: Replace all local image paths in Markdown with URLs
      imagePathToUrl.forEach((localPath, url) {
        markdownContent = markdownContent.replaceAll("($localPath)", "($url)");
      });

      // Step 5: Convert updated markdown content back to bytes
      Uint8List updatedMarkdownData =
          Uint8List.fromList(markdownContent.codeUnits);

      // Step 6: Upload the updated Markdown file with replaced URLs
      final result = await storage.createFile(
        bucketId: bucketLessonsId,
        fileId: 'unique()', // Generates a unique ID
        file: InputFile(bytes: updatedMarkdownData, filename: fileName),
      );

      // Return the URL for the uploaded Markdown file
      return "$appwriteEndpointId/storage/buckets/$bucketLessonsId/files/${result.$id}/view?project=$appwriteProjectId";
    } catch (e) {
      LogService.instance.error('Error uploading lesson: $e');
      rethrow;
    }
  }

  /// Helper function to check if a path is a local image path (not a URL and ends with image extensions)
  bool _isLocalImagePath(String path) {
    final urlPattern = RegExp(r'^(http|https)://'); // Check if path is a URL
    final imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp'
    ]; // Image extensions

    // Check if the path is not a URL and ends with a valid image extension
    return !urlPattern.hasMatch(path) &&
        imageExtensions.any((ext) => path.toLowerCase().endsWith(".$ext"));
  }

  /// Fetches image data from a path relative to the markdown file's location.
  Future<Uint8List?> fetchLocalImageData(String markdownFilePath, String imageRelativePath) async {
    // Get the directory of the markdown file
    final baseDirectory = p.dirname(markdownFilePath);

    // Resolve the absolute path of the image
    final imagePath = p.join(baseDirectory, Uri.decodeFull(imageRelativePath));
    final file = File(imagePath);

    try {
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        LogService.instance.info("File at $imagePath does not exist.");
        return null;
      }
    } catch (e) {
      LogService.instance.error("Error reading file: $e");
      return null;
    }
  }


  /// Helper function to upload image data to Appwrite
  Future<String> _uploadLessonImage(
      Uint8List imageData, String imagePath) async {
    try {
      final result = await storage.createFile(
        bucketId: bucketLessonsId,
        fileId: 'unique()', // Generates a unique ID
        file: InputFile(bytes: imageData, filename: imagePath.split('/').last),
      );
      return result.$id;
    } catch (e) {
      LogService.instance.error('Error uploading image: $e');
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
      LogService.instance.error('Error retrieving lesson by URL: $e');
      rethrow;
    }
  }

    Future<void> deleteLesson(String fileId) async {
    try {
      await storage.deleteFile(bucketId: bucketLessonsId, fileId: fileId);
      LogService.instance.info('Lesson file deleted successfully: $fileId');
    } catch (e) {
      LogService.instance.error('Error deleting lesson file: $e');
      throw Exception('Failed to delete lesson file');
    }
  }
}
