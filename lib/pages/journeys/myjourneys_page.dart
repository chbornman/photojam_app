import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/pages/journeys/journeycontainer.dart';
import 'package:photojam_app/pages/journeys/markdownviewer.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';

class MyJourneysPage extends StatelessWidget {
  final String userId;

  MyJourneysPage({required this.userId});

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Journeys"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchUserJourneys(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No journeys available."));
            }
            final userJourneys = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: userJourneys.map((journey) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ExpansionTile(
                      title: Text(
                        journey['title'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                      children: [
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: Future.wait(journey['lessons'].map<Future<Map<String, dynamic>>>((lessonUrl) async {
                            final title = await _fetchLessonTitle(context, lessonUrl);
                            return {'url': lessonUrl, 'title': title};
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

                            // Use JourneyContainer for displaying lessons inside the expansion tile
                            return JourneyContainer(
                              title: journey['title'],
                              lessons: lessonSnapshot.data!,
                              theme: theme,
                              onLessonTap: (lessonUrl) => _viewLesson(context, lessonUrl),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}