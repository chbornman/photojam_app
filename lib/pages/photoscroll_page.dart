import 'package:flutter/material.dart';
import 'dart:typed_data';

class PhotoScrollPage extends StatefulWidget {
  final List<Map<String, dynamic>> allSubmissions;
  final int initialIndex;

  PhotoScrollPage({required this.allSubmissions, required this.initialIndex});

  @override
  _PhotoScrollPageState createState() => _PhotoScrollPageState();
}

class _PhotoScrollPageState extends State<PhotoScrollPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialPosition();
    });
  }

  void _scrollToInitialPosition() {
    double offset = 0.0;
    for (int i = 0; i < widget.initialIndex; i++) {
      offset += (widget.allSubmissions[i]['photos'] as List<Uint8List?>).length * 300.0; // Estimated height per photo
    }
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
          final jamTitle = submission['jamTitle'];
          final photos = submission['photos'] as List<Uint8List?>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  jamTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...photos.map((photoData) {
                return photoData != null
                    ? Image.memory(
                        photoData,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.contain, // Ensure the full image is shown without cropping
                      )
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        height: 300,
                        color: Colors.grey,
                        child: Center(child: Text("Image not available")),
                      );
              }).toList(),
              const SizedBox(height: 40), // Space between sections
            ],
          );
        },
      ),
    );
  }
}