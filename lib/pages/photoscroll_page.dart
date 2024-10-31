import 'package:flutter/material.dart';
import 'dart:typed_data';

class PhotoScrollPage extends StatefulWidget {
  final List<Map<String, dynamic>> allSubmissions;
  final int initialSubmissionIndex;
  final int initialPhotoIndex;

  PhotoScrollPage({
    required this.allSubmissions,
    required this.initialSubmissionIndex,
    required this.initialPhotoIndex,
  });

  @override
  _PhotoScrollPageState createState() => _PhotoScrollPageState();
}

class _PhotoScrollPageState extends State<PhotoScrollPage> {
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _photoKeys = {}; // Keys for each photo

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialPosition();
    });
  }

Future<void> _scrollToInitialPosition() async {
  double offset = 0.0;

  // Loop through each photo up to the clicked photo to accumulate the total height
  for (int i = 0; i < widget.initialSubmissionIndex; i++) {
    final photos = widget.allSubmissions[i]['photos'] as List<Uint8List?>;
    for (int j = 0; j < photos.length; j++) {
      final key = _photoKeys[i * 100 + j];
      if (key != null && key.currentContext != null) {
        final photoHeight = key.currentContext!.size!.height;
        offset += photoHeight;
      }
    }
  }

  // Accumulate the heights within the target section up to the selected photo index
  final targetPhotos = widget.allSubmissions[widget.initialSubmissionIndex]['photos'] as List<Uint8List?>;
  for (int k = 0; k < widget.initialPhotoIndex; k++) {
    final key = _photoKeys[widget.initialSubmissionIndex * 100 + k];
    if (key != null && key.currentContext != null) {
      final photoHeight = key.currentContext!.size!.height;
      offset += photoHeight;
    }
  }

  // Scroll to the accumulated offset
  _scrollController.jumpTo(offset);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Photos"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.allSubmissions.length,
        itemBuilder: (context, index) {
          final submission = widget.allSubmissions[index];
          final photos = submission['photos'] as List<Uint8List?>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed title Text widget here

              ...photos.asMap().entries.map((entry) {
                final photoIndex = entry.key;
                final photoData = entry.value;

                // Generate a unique key for each photo
                final photoKey = GlobalKey();
                _photoKeys[index * 100 + photoIndex] = photoKey;

                return photoData != null
                    ? Image.memory(
                        photoData,
                        key: photoKey, // Attach the key to each photo
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        height: 300, // Default height if image not available
                        color: Colors.grey,
                        child: Center(child: Text("Image not available")),
                      );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
