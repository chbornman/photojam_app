import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:photojam_app/services/log_service.dart';

class PhotoCacheService {
  Future<Uint8List?> getImage(
    String photoUrl,
    String authToken,
    Future<Uint8List?> Function() fetchFromNetwork,
  ) async {
    try {
      final cacheFile = await _getImageCacheFile(photoUrl);

      if (await cacheFile.exists()) {
        return await cacheFile.readAsBytes();
      }

      final imageData = await fetchFromNetwork();
      if (imageData != null) {
        await cacheFile.writeAsBytes(imageData);
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
}