import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:photojam_app/core/services/log_service.dart';

class PhotoCacheService {
  // In-memory cache for web and as an additional layer for mobile
  final Map<String, Uint8List> _memoryCache = {};

  Future<Uint8List?> getImage(
    String photoUrl,
    String authToken,
    Future<Uint8List> Function() fetchFromNetwork,
  ) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(photoUrl)) {
        LogService.instance.info('Retrieved photo from memory cache: $photoUrl');
        return _memoryCache[photoUrl];
      }

      // For web platform, skip file system operations
      if (!kIsWeb) {
        // Check disk cache
        try {
          final cacheFile = await _getImageCacheFile(photoUrl);
          if (await cacheFile.exists()) {
            final imageData = await cacheFile.readAsBytes();
            _memoryCache[photoUrl] = imageData; // Also cache in memory
            LogService.instance.info('Retrieved photo from disk cache: $photoUrl');
            return imageData;
          }
        } catch (e) {
          LogService.instance.error('Error accessing disk cache: $e');
          // Continue to network fetch if disk cache fails
        }
      }

      // Fetch from network if not found in cache
      final imageData = await fetchFromNetwork();
      
      // Store in memory cache
      _memoryCache[photoUrl] = imageData;
      
      // Store in disk cache for mobile platforms
      if (!kIsWeb) {
        try {
          final cacheFile = await _getImageCacheFile(photoUrl);
          await cacheFile.writeAsBytes(imageData);
          LogService.instance.info('Cached photo to disk: $photoUrl');
        } catch (e) {
          LogService.instance.error('Error writing to disk cache: $e');
          // Continue even if disk cache fails
        }
      }

      return imageData;
    } catch (e) {
      LogService.instance.error('Error handling image: $e');
      return null;
    }
  }

  Future<File> _getImageCacheFile(String photoUrl) async {
    final cacheDir = await getTemporaryDirectory();
    final sanitizedFileName = sha256.convert(utf8.encode(photoUrl)).toString();
    return File('${cacheDir.path}/$sanitizedFileName.jpg');
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }
}