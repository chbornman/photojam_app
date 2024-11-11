import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/facilitator_signup_page.dart';
import 'package:photojam_app/pages/jams/jamsignup_page.dart';
import 'package:photojam_app/pages/membership_signup_page.dart';
import 'package:photojam_app/utilities/standard_card.dart';
import 'package:photojam_app/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Document> userJams = []; // List to hold user jams as Documents
  Document? nextJam; // Holds the next upcoming jam

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthAPI>(context, listen: false).userid;
      if (userId != null) {
        _fetchUserJams();
      } else {
        LogService.instance.info(
            "User ID is null, delaying fetch until user is authenticated.");
      }
    });
  }

  Future<void> _fetchUserJams() async {
    final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
    final userId = Provider.of<AuthAPI>(context, listen: false).userid;

    final jams = await databaseApi.getUserJamsWithSubmissions(userId!);
    jams.sort((a, b) {
      DateTime dateA = DateTime.parse(a.data['jam']['date']);
      DateTime dateB = DateTime.parse(b.data['jam']['date']);
      return dateA.compareTo(dateB);
    });

    if (mounted)
      setState(() {
        userJams = jams;
        try {
          nextJam = userJams.firstWhere(
            (cal) =>
                DateTime.parse(cal.data['jam']['date']).isAfter(DateTime.now()),
          );
        } catch (e) {
          nextJam = null;
        }
      });
  }

  void _goToExternalLink(String url) {
    final Uri zoomUri = Uri.parse(url);
    if (zoomUri.hasScheme) {
      launchUrl(zoomUri);
    } else {
      LogService.instance.info("Invalid Zoom URL");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final userRole = context.watch<UserDataProvider>().userRole;

    // Check if the next jam is within the next hour
    bool isNextJamWithinHour() {
      if (nextJam == null) return false;
      final jamDate = DateTime.parse(nextJam!.data['jam']['date']);
      final now = DateTime.now();
      final difference = jamDate.difference(now).inMinutes;
      return difference <= 60 && difference >= 0;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: Join the Jam
            Text(
              'Join the Jam',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            // Sign Up for Jam Card
            StandardCard(
              icon: Icons.add_circle_outline,
              title: "Sign Up for a Jam",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamSignupPage()),
                );
              },
            ),

            // Join Next Jam Card
            if (isNextJamWithinHour())
              StandardCard(
                icon: Icons.video_call,
                title: 'Join Your Next Scheduled Jam',
                subtitle:
                    'Scheduled on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(nextJam!.data['jam']['date']))}',
                onTap: () {
                  if (nextJam!.data['jam']['zoom_link'] != null) {
                    _goToExternalLink(nextJam!.data['jam']['zoom_link']);
                  }
                },
              ),

            // Signal link Card
            if (userRole != 'nonmember') ...[
              StandardCard(
                icon: Icons.chat,
                title: "Go to the Signal Chat",
                onTap: () {
                  _goToExternalLink(signalGroupUrl);
                },
              ),
            ],

            // Become a member Card
            if (userRole == 'nonmember') ...[
              StandardCard(
                icon: Icons.person_add,
                title: "Become a Member",
                subtitle: "Join our community and enjoy exclusive benefits",
                onTap: () {
                  // Navigate to membership signup page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MembershipSignupPage()),
                  );
                },
              ),
            ]

            // Become a facilitator Card
            else if (userRole == 'member') ...[
              StandardCard(
                icon: Icons.person_add,
                title: "Become a Facilitator",
                subtitle: "Lead Jams and share your photography passion",
                onTap: () {
                  // Navigate to facilitator signup page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FacilitatorSignupPage()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
