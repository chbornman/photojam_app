import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/log_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class PhotoSelectPage extends StatefulWidget {
  final List<Map<String, dynamic>> allSubmissions;
  final int initialSubmissionIndex;
  final int initialPhotoIndex;

  const PhotoSelectPage({
    Key? key,
    required this.allSubmissions,
    required this.initialSubmissionIndex,
    required this.initialPhotoIndex,
  }) : super(key: key);

  @override
  _PhotoSelectPageState createState() => _PhotoSelectPageState();
}

class _PhotoSelectPageState extends State<PhotoSelectPage>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> loadedSubmissions = [];
  Uint8List? activePhotoData; // Track the currently pressed photo

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllPhotos();
  }

  Future<void> _loadAllPhotos() async {
    try {
      for (var submission in widget.allSubmissions) {
        loadedSubmissions.add(submission);
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      LogService.instance.error("Error loading photos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to share image
  Future<void> _shareImage(Uint8List photoData) async {
    try {
      // Haptic feedback on long press
      HapticFeedback.mediumImpact();

      // Save the image temporarily to share
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/shared_image.png';
      final file = await File(filePath).writeAsBytes(photoData);

      // Use share_plus to trigger iOS share sheet
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      LogService.instance.error("Error sharing photo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sharing photo.')),
      );
    }
  }

  // Helper function to format date and time
  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      LogService.instance.error("Error formatting date: $e");
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Select"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              key: const PageStorageKey('photoSelectPageListView'),
              itemCount: loadedSubmissions.length,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              itemBuilder: (context, index) {
                final submission = loadedSubmissions[index];
                final photos = submission['photos'] as List<Uint8List?>;
                final jamTitle = submission['jamTitle'] ?? 'Untitled';
                final date = submission['date'] ?? 'Unknown Date';

                return Card(
                  elevation: 10,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  shadowColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jamTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: photos.map((photoData) {
                          return GestureDetector(
                            onLongPressStart: (_) {
                              setState(() {
                                activePhotoData = photoData;
                              });
                            },
                            onLongPressEnd: (_) async {
                              setState(() {
                                activePhotoData = null;
                              });
                              if (photoData != null) {
                                await _shareImage(photoData);
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: photoData != null
                                        ? Image.memory(
                                            photoData,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: 200,
                                            color: const Color.fromARGB(
                                                255, 16, 104, 82),
                                            child: const Center(
                                              child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Color.fromARGB(
                                                      255, 228, 224, 224),
                                                  size: 50),
                                            ),
                                          ),
                                  ),
                                ),
                                if (activePhotoData == photoData)
                                  Positioned.fill(
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
