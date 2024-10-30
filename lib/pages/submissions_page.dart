import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  final databaseApi = DatabaseAPI();
  final auth = AuthAPI(); // Instantiate AuthAPI

  List<Map<String, dynamic>> AllSubmissions = [];
  bool isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _fetchAllSubmissions();
  }

  Future<void> _fetchAllSubmissions() async {
    try {
      final userId = await auth.fetchUserId();
      print("User ID fetched in _fetchAllSubmissions: $userId");

      if (userId == null || userId.isEmpty) {
        print('User ID is still not available after fetching.');
        throw Exception("User ID is not available");
      }

      // Retrieve all submissions for the authenticated user, passing userId as an argument
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photos =
            List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        // Retrieve the title from the embedded jam relationship
        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title')) {
          jamTitle = jamData['title'] ?? 'Untitled';
        }

        submissions.add({
          'date': date,
          'jamTitle': jamTitle,
          'photos': photos,
        });
      }

      // Sort submissions by date in descending order
      submissions.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        AllSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching All submissions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Submissions"),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AllSubmissions.isEmpty
              ? Center(
                  child: Text(
                    "No submissions yet",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: AllSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = AllSubmissions[index];
                    final jamTitle = submission['jamTitle'];
                    final photos = submission['photos'] as List<String>;

                    final backgroundColor =
                        index % 2 == 0 ? Colors.white : secondaryAccentColor;

                    return Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius:
                            BorderRadius.circular(defaultCornerRadius),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jamTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: photos
                                .map((photoUrl) => ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          defaultCornerRadius),
                                      child: Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                      ),
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
