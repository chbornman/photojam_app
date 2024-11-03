import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoScrollPage extends StatefulWidget {
  final List<Map<String, dynamic>> allSubmissions;
  final int initialSubmissionIndex;
  final int initialPhotoIndex;

  const PhotoScrollPage({
    Key? key,
    required this.allSubmissions,
    required this.initialSubmissionIndex,
    required this.initialPhotoIndex,
  }) : super(key: key);

  @override
  _PhotoScrollPageState createState() => _PhotoScrollPageState();
}

class _PhotoScrollPageState extends State<PhotoScrollPage>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> loadedSubmissions = [];

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
      print("Error loading photos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Scroll"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              key: const PageStorageKey('photoScrollPageListView'),
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
                    borderRadius: BorderRadius.circular(
                        8.0), // Slight rounding for card corners
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
                              date,
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0), // Inset the images
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Slight rounding for image corners
                              child: photoData != null
                                  ? Image.memory(
                                      photoData,
                                      width: double.infinity,
                                      fit: BoxFit
                                          .contain, // Retains aspect ratio
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: const Color.fromARGB(
                                          255, 16, 104, 82),
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: Color.fromARGB(
                                                255, 228, 224, 224),
                                            size: 50),
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }
}
