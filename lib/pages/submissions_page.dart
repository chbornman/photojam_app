import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true; // To manage loading state

  @override
  void initState() {
    super.initState();
    _fetchAllSubmissions();
  }


  Future<void> _fetchAllSubmissions() async {
    try {
      // Access AuthAPI through Provider to get the user ID
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId == null || userId.isEmpty) {
        print('User ID is not available.');
        throw Exception("User ID is not available.");
      }

      // Access DatabaseAPI through Provider to get the submissions
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      setState(() {
        allSubmissions = response
            .map((doc) => doc.data)
            .toList()
            .cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching submissions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allSubmissions.isEmpty
              ? const Center(child: Text('No submissions found.'))
              : ListView.builder(
                  itemCount: allSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = allSubmissions[index];
                    return ListTile(
                      title: Text(submission['title'] ?? 'Untitled Submission'),
                      subtitle: Text(submission['date'] ?? 'No date'),
                    );
                  },
                ),
    );
  }
}