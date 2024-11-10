import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/jams/jamdetails_page.dart';
import 'package:photojam_app/pages/jams/jamsignup_page.dart';
import 'package:photojam_app/utilities/standard_card.dart';
import 'package:provider/provider.dart';

class JamPage extends StatefulWidget {
  const JamPage({super.key});

  @override
  _JamPageState createState() => _JamPageState();
}

class _JamPageState extends State<JamPage> {
  String? currentJamId;
  String jamTitle = "Jam";
  List<Document> upcomingJams = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingJams();
  }

  Future<void> _fetchUpcomingJams() async {
    try {
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userid;

      if (userId != null) {
        final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
        final response = await databaseApi.getUpcomingJamsByUser(userId);

        setState(() {
          upcomingJams = response.documents;
        });
      }
    } catch (e) {
      LogService.instance.error('Error fetching upcoming jams: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StandardCard(
              icon: Icons.add_circle_outline,
              title: "Sign Up for a Jam",
              subtitle: "Experience the world's nicest photo community",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamSignupPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Upcoming Jams",
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: upcomingJams.isEmpty
                  ? Center(
                      child: Text(
                        "No upcoming jams.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: upcomingJams.length,
                      itemBuilder: (context, index) {
                        final jam = upcomingJams[index];
                        final jamDate = DateTime.parse(jam.data['date']);
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            leading: Icon(
                              Icons.event,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                            title: Text(
                              jam.data['title'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${jamDate.toLocal()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jam.data['description'] ??
                                      "Join us for a memorable event!", // Add description if available
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              // Navigate to the Jam Details Page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JamDetailsPage(jam: jam),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
