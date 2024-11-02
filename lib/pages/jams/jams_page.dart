import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/jams/jamsignup_page.dart';
import 'package:photojam_app/pages/jams/myjams_page.dart';
import 'package:photojam_app/standard_button.dart';
import 'package:photojam_app/standard_dialog.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/constants/constants.dart';

class JamPage extends StatefulWidget {
  @override
  _JamPageState createState() => _JamPageState();
}

class _JamPageState extends State<JamPage> {
  String? currentJamId;
  String jamTitle = "Jam";

  @override
  void initState() {
    super.initState();
    _fetchLatestJam();
  }

  Future<void> _fetchLatestJam() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId != null) {
        final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
        final response = await databaseApi.getJamsByUser(userId);

        if (response.documents.isNotEmpty) {
          response.documents.sort((a, b) {
            final dateA = DateTime.parse(a.data['date']);
            final dateB = DateTime.parse(b.data['date']);
            return dateB.compareTo(dateA); // Latest jam first
          });

          final latestJam = response.documents.first;
          setState(() {
            currentJamId = latestJam.$id;
            jamTitle = latestJam.data['title'] ?? "Jam";
          });
        } else {
          print("No jams found for this user.");
        }
      }
    } catch (e) {
      print('Error fetching the latest jam: $e');
    }
  }

  void _goToMyJams() {
    final auth = Provider.of<AuthAPI>(context, listen: false);
    final userId = auth.userid;

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyJamsPage(userId: userId),
        ),
      );
    } else {
      print('User ID is not available');
    }
  }

  Future<void> _openSignUpForJamDialog() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(jamTitle),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StandardButton(label: Text("View My Jams"), onPressed: _goToMyJams),
            StandardButton(
              label: Text('Sign up for a Jam'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamSignupPage()),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
