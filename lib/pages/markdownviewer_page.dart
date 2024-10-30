import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class MarkdownViewerPage extends StatelessWidget {
  final String url;

  MarkdownViewerPage({required this.url});

  Future<String> _fetchMarkdownContent() async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load markdown content');
      }
    } catch (e) {
      print('Error fetching markdown content: $e');
      return 'Error loading content';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lesson Content")),
      body: FutureBuilder<String>(
        future: _fetchMarkdownContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading content"));
          }
          return Markdown(
            data: snapshot.data ?? 'No content available',
          );
        },
      ),
    );
  }
}