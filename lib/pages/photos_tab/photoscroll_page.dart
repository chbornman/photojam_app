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

class _PhotoScrollPageState extends State<PhotoScrollPage> with AutomaticKeepAliveClientMixin {
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
      // Simulate fetching all photos by looping through submissions and loading them
      for (var submission in widget.allSubmissions) {

        // Fetch any additional resources if necessary
        // Add submission with all photos loaded into loadedSubmissions
        loadedSubmissions.add(submission);
      }
      setState(() {
        isLoading = false; // All photos are now loaded
      });
    } catch (e) {
      print("Error loading photos: $e");
      setState(() {
        isLoading = false; // Handle errors and stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Scroll"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              key: const PageStorageKey('photoScrollPageListView'),
              itemCount: loadedSubmissions.length,
              itemBuilder: (context, index) {
                final submission = loadedSubmissions[index];
                final photos = submission['photos'] as List<Uint8List?>;
                final jamTitle = submission['jamTitle'] ?? 'Untitled';
                final date = submission['date'] ?? 'Unknown Date';

                return Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jamTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: photos.map((photoData) {
                          return photoData != null
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Image.memory(
                                    photoData,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey,
                                  child: const Icon(Icons.image_not_supported),
                                );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}