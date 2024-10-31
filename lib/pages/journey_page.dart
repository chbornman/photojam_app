import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/alljourneys_page.dart';
import 'package:photojam_app/pages/markdownviewer_page.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:http/http.dart' as http;


class JourneyPage extends StatefulWidget {
  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  String currentJourneyId = "currentJourneyId"; // Placeholder for the current journey ID
  String journeyTitle = "Journey"; // Placeholder for the journey title
  List<Map<String, dynamic>> lessons = []; // Stores lessons for the current journey

  @override
  void initState() {
    super.initState();
    _setCurrentJourneyId();
  }

  Future<void> _setCurrentJourneyId() async {
    try {
      // Access AuthAPI through Provider to get the user ID
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId != null) {
        // Access DatabaseAPI through Provider to get the journeys
        final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
        final response = await databaseApi.getJourneysByUser(userId);

        if (response.documents.isNotEmpty) {
          setState(() {
            currentJourneyId = response.documents[0].$id;
            journeyTitle = response.documents[0].data['title'];
            
            // Retrieve lessons as List<String> URLs
            final lessonUrls = response.documents[0].data['lessons'] as List<dynamic>? ?? [];
            _fetchLessonsWithTitles(lessonUrls);
          });
        }
      }
    } catch (e) {
      print('Error setting current journey ID: $e');
    }
  }

  Future<void> _fetchLessonsWithTitles(List<dynamic> lessonUrls) async {
    final List<Map<String, dynamic>> fetchedLessons = [];

    for (String url in lessonUrls.cast<String>()) {
      final title = await _fetchTitleFromMarkdown(url);
      fetchedLessons.add({'url': url, 'title': title});
    }

    setState(() {
      lessons = fetchedLessons;
    });
  }

  Future<String> _fetchTitleFromMarkdown(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        if (lines.isNotEmpty) {
          String title = lines.first.trim().replaceFirst(RegExp(r'^#+\s*'), '');
          return title.isNotEmpty ? title : 'Untitled Lesson';
        }
        return 'Untitled Lesson';
      } else {
        throw Exception('Failed to load markdown content');
      }
    } catch (e) {
      print('Error fetching markdown content: $e');
      return 'Untitled Lesson';
    }
  }

  Future<void> _viewLesson(String lessonUrl) async {
    try {
      final storageApi = Provider.of<StorageAPI>(context, listen: false);
      final lessonData = await storageApi.getLesson(lessonUrl);

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
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lessons.map((lesson) => ListTile(
              title: Text(lesson['title']),
              onTap: () => _viewLesson(lesson['url']),
              trailing: Icon(Icons.arrow_forward, color: Colors.black),
            )),
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