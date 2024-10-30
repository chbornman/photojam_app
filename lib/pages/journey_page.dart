import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/pages/markdownviewer_page.dart';
import 'package:http/http.dart' as http;

class JourneyPage extends StatefulWidget {
  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final databaseApi = DatabaseAPI();
  final storageApi = StorageAPI();
  final auth = AuthAPI();

  String currentJourneyId =
      "currentJourneyId"; // Placeholder for the current journey ID
  String journeyTitle = "Journey"; // Placeholder for the journey title
  List<Map<String, dynamic>> lessons =
      []; // Stores lessons for the current journey

  @override
  void initState() {
    super.initState();
    _setCurrentJourneyId();
  }

  Future<void> _fetchCurrentJourneyLessons() async {
    try {
      final journey = await databaseApi.getJourneyById(currentJourneyId);
      journeyTitle =
          journey.data['title'] ?? 'Current Journey'; // Set the journey title

      final lessonUrls = journey.data['lessons'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> fetchedLessons = [];

      for (String url in lessonUrls) {
        // Fetch the markdown file content
        final title = await _fetchTitleFromMarkdown(url);

        // Add to lessons list with the title from the file
        fetchedLessons.add({
          'url': url,
          'title': title,
        });
      }

      setState(() {
        lessons = fetchedLessons;
      });
    } catch (e) {
      print('Error fetching lessons: $e');
    }
  }

// Helper function to fetch the title from the first line of a markdown file
  Future<String> _fetchTitleFromMarkdown(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Get the first line and remove leading "#" and spaces
        final lines = response.body.split('\n');
        if (lines.isNotEmpty) {
          String title = lines.first.trim();
          title = title.replaceFirst(
              RegExp(r'^#+\s*'), ''); // Remove leading "#" and spaces
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

  Future<void> _setCurrentJourneyId() async {
    try {
      // Fetch and wait for the user ID to be available
      final userId = await auth.fetchUserId();
      print("User ID fetched in _setCurrentJourneyId: $userId");

      if (userId == null || userId.isEmpty) {
        print('User ID is still not available after fetching.');
        throw Exception("User ID is not available");
      }

      // Fetch all journeys and filter by user ID in participant_ids
      final journeyList = await databaseApi.getAllJourneys();
      final userJourneys = journeyList.documents.where((journey) {
        final participantIds = journey.data['participant_ids'] as List<dynamic>;
        return participantIds.contains(userId);
      }).toList();

      if (userJourneys.isNotEmpty) {
        // Sort journeys by start_date in descending order
        userJourneys.sort((a, b) {
          DateTime dateA = DateTime.parse(a.data['start_date']);
          DateTime dateB = DateTime.parse(b.data['start_date']);
          return dateB.compareTo(dateA); // Descending order
        });

        // Set currentJourneyId to the most recent journey's ID
        setState(() {
          currentJourneyId = userJourneys.first.$id;
        });

        // Now fetch lessons for this journey
        _fetchCurrentJourneyLessons();
      } else {
        print('No journeys found for this user.');
      }
    } catch (e) {
      print('Error setting current journey ID: $e');
    }
  }

  void _openLesson(String lessonId) async {
    try {
      await storageApi.downloadLesson(
          lessonId, '/path/to/save'); // Replace with actual path
      print('Lesson $lessonId downloaded');
    } catch (e) {
      print('Error opening lesson: $e');
    }
  }

void _goToAllJourneys() async {
  final userId = await auth.fetchUserId();
  print("User ID fetched in _goToAllJourneys: $userId");

  if (userId == null || userId.isEmpty) {
    print('User ID is still not available after fetching.');
    throw Exception("User ID is not available");
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AllJourneysPage(userId: userId),
    ),
  );
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
                  title: Text(
                    lesson['title'],
                    style: const TextStyle(color: Colors.black),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MarkdownViewerPage(url: lesson['url']),
                    ),
                  ),
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

class AllJourneysPage extends StatelessWidget {
  final DatabaseAPI databaseApi = DatabaseAPI();
  final String userId;

  AllJourneysPage({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchUserJourneys() async {
    try {
      // Fetch all journeys and filter by participant_ids containing the userId
      final response = await databaseApi.getAllJourneys();
      final journeys = response.documents.where((doc) {
        final participantIds = doc.data['participant_ids'] as List<dynamic>;
        return participantIds.contains(userId);
      }).map((doc) => {
        'id': doc.$id,
        'title': doc.data['title'] ?? 'Untitled Journey'
      }).toList();

      return journeys;
    } catch (e) {
      print('Error fetching user journeys: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Journeys")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserJourneys(),
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
              return ListTile(
                title: Text(journey['title']),
                onTap: () {
                  // Navigate to the specific journey page with lessons
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JourneyLessonsPage(
                        journeyId: journey['id'],
                        journeyTitle: journey['title'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class JourneyLessonsPage extends StatelessWidget {
  final String journeyId;
  final String journeyTitle;
  final databaseApi = DatabaseAPI();
  
  JourneyLessonsPage({required this.journeyId, required this.journeyTitle});

  // Fetch lessons for a specific journey, extracting titles from the first line of each markdown file
  Future<List<Map<String, dynamic>>> _fetchLessons() async {
    try {
      final journey = await databaseApi.getJourneyById(journeyId);
      final lessonUrls = journey.data['lessons'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> fetchedLessons = [];

      for (String url in lessonUrls) {
        final title = await _fetchTitleFromMarkdown(url);
        fetchedLessons.add({
          'url': url,
          'title': title,
        });
      }

      return fetchedLessons;
    } catch (e) {
      print('Error fetching lessons: $e');
      return [];
    }
  }

  // Helper function to fetch the title from the first line of a markdown file
  Future<String> _fetchTitleFromMarkdown(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        if (lines.isNotEmpty) {
          String title = lines.first.trim();
          title = title.replaceFirst(RegExp(r'^#+\s*'), ''); // Remove leading "#" and spaces
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(journeyTitle)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No lessons available for this journey."));
          }
          final lessons = snapshot.data!;
          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                title: Text(
                  lesson['title'],
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkdownViewerPage(url: lesson['url']),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          );
        },
      ),
    );
  }
}