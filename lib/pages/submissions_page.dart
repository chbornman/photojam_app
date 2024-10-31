import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:provider/provider.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  List<Map<String, dynamic>> allSubmissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllSubmissions();
  }

  Future<void> _fetchAllSubmissions() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId == null || userId.isEmpty) throw Exception("User ID is not available.");

      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getSubmissionsByUser(userId: userId);

      List<Map<String, dynamic>> submissions = [];
      for (var doc in response) {
        final date = doc.data['date'] ?? 'Unknown Date';
        final photos = List<String>.from(doc.data['photos'] ?? []).take(3).toList();

        String jamTitle = 'Untitled';
        final jamData = doc.data['jam'];
        if (jamData is Map && jamData.containsKey('title')) jamTitle = jamData['title'] ?? 'Untitled';

        submissions.add({
          'date': date,
          'jamTitle': jamTitle,
          'photos': photos,
        });
      }

      submissions.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        allSubmissions = submissions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching submissions: $e');
      setState(() => isLoading = false);
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
          : allSubmissions.isEmpty
              ? Center(child: Text("No submissions yet", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))
              : ListView.builder(
                  itemCount: allSubmissions.length,
                  itemBuilder: (context, index) {
                    final submission = allSubmissions[index];
                    final jamTitle = submission['jamTitle'];
                    final photos = submission['photos'] as List<String>;

                    final backgroundColor = index % 2 == 0 ? Colors.white : Theme.of(context).secondaryHeaderColor;

                    return Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jamTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: photos.map((photoUrl) => ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(photoUrl, fit: BoxFit.cover, width: 100, height: 100),
                              )
                            ).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}