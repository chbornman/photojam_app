import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/markdownviewer_page.dart';
import 'package:photojam_app/pages/alljourneys_page.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/constants/constants.dart';

class JourneyPage extends StatefulWidget {
  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  String? currentJourneyId;
  String journeyTitle = "Journey";
  List<Map<String, dynamic>> lessons = [];

  @override
  void initState() {
    super.initState();
    _fetchLatestJourney();
  }

  Future<void> _fetchLatestJourney() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId != null) {
        final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
        final response = await databaseApi.getJourneysByUser(userId);

        if (response.documents.isNotEmpty) {
          response.documents.sort((a, b) {
            final dateA = DateTime.parse(a.data['start_date']);
            final dateB = DateTime.parse(b.data['start_date']);
            return dateB.compareTo(dateA); // Latest journey first
          });

          final latestJourney = response.documents.first;
          setState(() {
            currentJourneyId = latestJourney.$id;
            journeyTitle = latestJourney.data['title'] ?? "Journey";
          });

          final lessonUrls = latestJourney.data['lessons'] as List<dynamic>? ?? [];
          _fetchLessonsByURLs(lessonUrls);
        } else {
          print("No journeys found for this user.");
        }
      }
    } catch (e) {
      print('Error fetching the latest journey: $e');
    }
  }

  Future<void> _fetchLessonsByURLs(List<dynamic> lessonUrls) async {
    final storageApi = Provider.of<StorageAPI>(context, listen: false);
    List<Map<String, dynamic>> fetchedLessons = [];

    for (String url in lessonUrls) {
      try {
        final lessonData = await storageApi.getLessonByURL(url); // Use URL directly
        final title = _extractTitleFromMarkdown(lessonData);
        fetchedLessons.add({'url': url, 'title': title});
      } catch (e) {
        print("Error fetching lesson title: $e");
        fetchedLessons.add({'url': url, 'title': 'Untitled Lesson'});
      }
    }

    setState(() {
      lessons = fetchedLessons;
    });
  }

  String _extractTitleFromMarkdown(Uint8List lessonData) {
    final content = utf8.decode(lessonData);
    final firstLine = content.split('\n').first.trim();
    return firstLine.startsWith('#') ? firstLine.replaceFirst('#', '').trim() : 'Untitled Lesson';
  }

  void _viewLesson(String lessonUrl) async {
    try {
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final lessonData = await storageApi.getLessonByURL(lessonUrl); // Use URL here
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerPage(content: lessonData),
        ),
      );
    } catch (e) {
      print('Error viewing lesson: $e');
    }
  }

  void _goToAllJourneys() {
    final auth = Provider.of<AuthAPI>(context, listen: false);
    final userId = auth.userid;

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllJourneysPage(userId: userId),
        ),
      );
    } else {
      print('User ID is not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(journeyTitle),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: lessons.map((lesson) => ListTile(
                  title: Text(lesson['title']),
                  onTap: () => _viewLesson(lesson['url']),
                  trailing: Icon(Icons.arrow_forward, color: Colors.black),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToAllJourneys,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, defaultButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
              ),
              child: const Text("View All Journeys"),
            ),
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}