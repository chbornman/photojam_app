import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart'; // Import AuthAPI

class JourneyPage extends StatefulWidget {
  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final databaseApi = DatabaseAPI();
  final storageApi = StorageAPI();
  final auth = AuthAPI(); // Instantiate AuthAPI

  String currentJourneyId =
      "currentJourneyId"; // Placeholder for the current journey ID
  List<Map<String, dynamic>> lessons =
      []; // Stores lessons for the current journey

  @override
  void initState() {
    super.initState();
    _setCurrentJourneyId();
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
    final journeyList = await databaseApi.getPastJourneys();
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

  Future<void> _fetchCurrentJourneyLessons() async {
    try {
      final journey = await databaseApi.getJourneyById(currentJourneyId);
      setState(() {
        lessons = List<Map<String, dynamic>>.from(journey.data['lessonIds']
                ?.map((id) => {'id': id, 'title': 'Lesson $id'}) ??
            []);
      });
    } catch (e) {
      print('Error fetching lessons: $e');
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

void _goToPastJourneys() async {
  // Fetch the user ID
  final userId = await auth.fetchUserId();
  
  // Check if the user ID is valid before navigating
  if (userId != null && userId.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PastJourneysPage(userId: userId)), // Pass userId to PastJourneysPage
    );
  } else {
    print("User ID not available for PastJourneysPage");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Journey")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Journey Lessons
            Text(
              'Current Journey Lessons',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...lessons.map((lesson) => ListTile(
                  title: Text(lesson['title']),
                  onTap: () => _openLesson(lesson['id']),
                  trailing: Icon(Icons.arrow_forward),
                )),
            SizedBox(height: 20),

            // Past Journeys Button
            ElevatedButton(
              onPressed: _goToPastJourneys,
              child: Text("View Past Journeys"),
            ),
          ],
        ),
      ),
    );
  }
}

class PastJourneysPage extends StatelessWidget {
  final DatabaseAPI databaseApi = DatabaseAPI();
  final String userId; // Add userId as a parameter

  PastJourneysPage({required this.userId}); // Require userId in constructor

  Future<List<Map<String, dynamic>>> _fetchPastJourneys() async {
    try {
      // Pass userId to getPastJourneys
      final response = await databaseApi.getPastJourneys(); // Implement getPastJourneys in DatabaseAPI
      return List<Map<String, dynamic>>.from(response.documents
          .map((doc) => {'id': doc.$id, 'title': doc.data['name']}));
    } catch (e) {
      print('Error fetching past journeys: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Journeys")),
      body: FutureBuilder(
        future: _fetchPastJourneys(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No past journeys available."));
          }
          final pastJourneys = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: pastJourneys.length,
            itemBuilder: (context, index) {
              final journey = pastJourneys[index];
              return ListTile(
                title: Text(journey['title']),
                onTap: () {
                  // Navigate to lesson list for this journey
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => JourneyLessonsPage(
                            journeyId: journey['id'],
                            journeyTitle: journey['title'])),
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

// Define JourneyLessonsPage to display lessons within a selected past journey
class JourneyLessonsPage extends StatelessWidget {
  final String journeyId;
  final String journeyTitle;
  final databaseApi = DatabaseAPI();
  final storageApi = StorageAPI();

  JourneyLessonsPage({required this.journeyId, required this.journeyTitle});

  Future<List<Map<String, dynamic>>> _fetchLessons() async {
    try {
      final journey = await databaseApi.getJourneyById(journeyId);
      return List<Map<String, dynamic>>.from(journey.data['lessonIds']
              ?.map((id) => {'id': id, 'title': 'Lesson $id'}) ??
          []);
    } catch (e) {
      print('Error fetching lessons: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(journeyTitle)),
      body: FutureBuilder(
        future: _fetchLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text("No lessons available for this journey."));
          }
          final lessons = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                title: Text(lesson['title']),
                onTap: () => storageApi.downloadLesson(
                    lesson['id'], '/path/to/save'), // Replace with actual path
              );
            },
          );
        },
      ),
    );
  }
}
