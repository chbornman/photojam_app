import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/markdownviewer_page.dart';
import 'package:provider/provider.dart';

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
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId != null) {
        final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
        final response = await databaseApi.getJourneysByUser(userId);
        
        if (response.documents.isNotEmpty) {
          setState(() {
            currentJourneyId = response.documents[0].$id;
            journeyTitle = response.documents[0].data['title'];
            lessons = response.documents[0].data['lessons'] ?? [];
          });
        }
      }
    } catch (e) {
      print('Error setting current journey ID: $e');
    }
  }

Future<void> _viewLesson(String lessonId) async {
  try {
    final storageApi = Provider.of<StorageAPI>(context, listen: false);
    final lessonData = await storageApi.getLesson(lessonId); // getLesson now returns Uint8List

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkdownViewerPage(content: lessonData), // Passing raw content
      ),
    );
  } catch (e) {
    print('Error viewing lesson: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(journeyTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return ListTile(
              title: Text(lesson['title'] ?? 'Untitled'),
              onTap: () => _viewLesson(lesson['url']),
            );
          },
        ),
      ),
    );
  }
}