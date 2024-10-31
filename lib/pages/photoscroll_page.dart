import 'package:flutter/material.dart';
import 'dart:typed_data';

class PhotoScrollPage extends StatelessWidget {
  final String jamTitle;
  final List<Uint8List?> photos;

  PhotoScrollPage({required this.jamTitle, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(jamTitle),
      ),
      body: ListView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photoData = photos[index];
          return photoData != null
              ? Image.memory(
                  photoData,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  color: Colors.grey,
                  child: Center(child: Text("Image not available")),
                );
        },
      ),
    );
  }
}