import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/pages/journeys/markdownviewer.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';

class AllJourneysPage extends StatelessWidget {
  final String userId;

  AllJourneysPage({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchUserJourneys(BuildContext context) async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getJourneysByUser(userId);

      return response.documents.map((doc) {
        return {
          'id': doc.$id,
          'title': doc.data['title'] ?? 'Untitled Journey',
          'lessons': doc.data['lessons'] as List<dynamic>? ?? []
        };
      }).toList();
    } catch (e) {
      print('Error fetching user journeys: $e');
      return [];
    }
  }

  Future<String> _fetchLessonTitle(BuildContext context, String lessonUrl) async {
    final storageApi = Provider.of<StorageAPI>(context, listen: false);
    try {
      Uint8List lessonData = await storageApi.getLessonByURL(lessonUrl);
      final content = utf8.decode(lessonData);
      final firstLine = content.split('\n').first.trim();
      return firstLine.startsWith('#') ? firstLine.replaceFirst('#', '').trim() : 'Untitled Lesson';
    } catch (e) {
      print('Error fetching lesson title: $e');
      return 'Untitled Lesson';
    }
  }

  void _viewLesson(BuildContext context, String lessonUrl) async {
    try {
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final lessonData = await storageApi.getLessonByURL(lessonUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewer(content: lessonData),
        ),
      );
    } catch (e) {
      print('Error viewing lesson: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Journeys")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserJourneys(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No journeys available."));
          }
          final userJourneys = snapshot.data!;
          return ListView.builder(
            itemCount: userJourneys.length,
            itemBuilder: (context, index) {
              final journey = userJourneys[index];
              return ExpansionTile(
                title: Text(journey['title']),
                children: [
                  FutureBuilder<List<Widget>>(
                    future: Future.wait(journey['lessons'].map<Future<Widget>>((lessonUrl) async {
                      final title = await _fetchLessonTitle(context, lessonUrl);
                      return ListTile(
                        title: Text(title),
                        onTap: () => _viewLesson(context, lessonUrl),
                      );
                    }).toList()),
                    builder: (context, lessonSnapshot) {
                      if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!lessonSnapshot.hasData || lessonSnapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("No lessons available."),
                        );
                      }
                      return Column(children: lessonSnapshot.data!);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}