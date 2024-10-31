import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'dart:typed_data';

class MarkdownViewerPage extends StatelessWidget {
  final Uint8List content;

  MarkdownViewerPage({required this.content});

  @override
  Widget build(BuildContext context) {
    // Decode Uint8List to String (Markdown content)
    final markdownText = utf8.decode(content);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lesson Content"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: markdownText, // Displaying the Markdown content
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}