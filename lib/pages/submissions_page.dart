import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  final databaseApi = DatabaseAPI();
  final auth = AuthAPI(); // Instantiate AuthAPI

  List<Map<String, dynamic>> pastSubmissions = [];
  bool isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _fetchPastSubmissions();
  }

  Future<void> _fetchPastSubmissions() async {
    try {
      // Fetch and wait for the user ID to be available
      final userId = await auth.fetchUserId();
      print("User ID fetched in _setCurrentJourneyId: $userId");

      if (userId == null || userId.isEmpty) {
        print('User ID is still not available after fetching.');
        throw Exception("User ID is not available");
      }
      // Retrieve past submissions for the authenticated user
      final response = await databaseApi.getPastSubmissions();

      // Process each submission to get relevant data
      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photos = List<String>.from(doc.data['photos'] ?? [])
            .take(3)
            .toList(); // Limit to 3 photos

        submissions.add({
          'date': date,
          'photos': photos,
        });
      }

      setState(() {
        pastSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching past submissions: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Submissions")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pastSubmissions.isEmpty
              ? Center(
                  child: Text(
                    "No submissions yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.builder(
                  itemCount: pastSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = pastSubmissions[index];
                    final date = submission['date'];
                    final photos = submission['photos'] as List<String>;

                    print(
                        'Photos for submission at index $index: $photos'); // Debugging output

                    final backgroundColor =
                        index % 2 == 0 ? Colors.white : Colors.grey[200];

                    return Container(
                      color: backgroundColor,
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: $date',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: photos
                                .map((photoUrl) => Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
