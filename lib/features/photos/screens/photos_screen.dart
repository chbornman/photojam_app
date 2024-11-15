import 'package:flutter/material.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';
import 'package:photojam_app/features/photos/screens/photos_content.dart';
import 'package:photojam_app/features/photos/controllers/photos_controller.dart';
import 'package:provider/provider.dart';
class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PhotosController(
        authAPI: context.read(),
        databaseAPI: context.read(),
        storageAPI: context.read(),
        cacheService: PhotoCacheService(),
      )..fetchSubmissions(),
      child: const PhotosContent(),
    );
  }
}