import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:share_plus/share_plus.dart';

class PhotoScrollPage extends ConsumerWidget {
  final Submission submission;

  const PhotoScrollPage({
    super.key,
    required this.submission,
  });

  // Fetch a photo from cache or storage
  Future<Uint8List?> _fetchPhoto(String fileId, WidgetRef ref) async {
    try {
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      final photoData = await storageNotifier.downloadFile(fileId);
      return photoData;
    } catch (e) {
      LogService.instance.error("Error fetching photo with ID $fileId: $e");
      return null;
    }
  }

  // Share an image
  Future<void> _shareImage(Uint8List photoData, BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/shared_image.png';
      final file = await File(filePath).writeAsBytes(photoData);

      await Share.shareXFiles([XFile(file.path)], text: 'Check out my PhotoJam submission!');
    } catch (e) {
      LogService.instance.error("Error sharing photo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sharing photo.')),
      );
    }
  }

  // Build each photo card
  Widget _buildPhotoCard(String fileId, WidgetRef ref) {
    return FutureBuilder<Uint8List?>(
      future: _fetchPhoto(fileId, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Icon(Icons.error, color: Colors.red),
          );
        } else {
          final photoData = snapshot.data;
          if (photoData == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            );
          }
          return GestureDetector(
            onLongPress: () async => await _shareImage(photoData, context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  photoData,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the Jam details using the jamByIdProvider
    final jamAsyncValue = ref.watch(jamByIdProvider(submission.jamId));

    return Scaffold(
      appBar: AppBar(
        title: jamAsyncValue.when(
          data: (jam) => Text(jam != null ? "Photos for ${jam.title}" : "Photos"),
          loading: () => const Text("Loading Jam..."),
          error: (error, stackTrace) => const Text("Error"),
        ),
      ),
      body: ListView.builder(
        itemCount: submission.photos.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final photoId = submission.photos[index];
          return _buildPhotoCard(photoId, ref);
        },
      ),
    );
  }
}
