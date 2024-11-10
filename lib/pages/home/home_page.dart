import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/facilitator_signup_page.dart';
import 'package:photojam_app/pages/jams/jamsignup_page.dart';
import 'package:photojam_app/pages/home/master_of_the_month_page.dart';
import 'package:photojam_app/pages/membership_signup_page.dart';
import 'package:photojam_app/utilities/standard_card.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Document> userJams = []; // List to hold user jams as Documents
  Document? nextJam; // Holds the next upcoming jam
  String? userRole; // State variable for storing user role

  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Retrieve user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthAPI>(context, listen: false).userid;
      if (userId != null) {
        _fetchUserJams();
      } else {
        LogService.instance.info("User ID is null, delaying fetch until user is authenticated.");
      }
    });
  }

  void _fetchUserRole() async {
    final authAPI = Provider.of<AuthAPI>(context, listen: false);
    try {
      final role = await authAPI.getUserRole();
      setState(() {
        userRole = role; // Update state with the retrieved user role
      });
    } catch (e) {
      setState(() {
        userRole = null; // Handle error if user role is not available
      });
    }
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
              subtitle: "Experience the world's nicest photo community",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamSignupPage()),
                );
              },
            ),
            const SizedBox(height: 10),

            // Join Next Jam Card
            StandardCard(
              icon: Icons.video_call,
              title: nextJam != null
                  ? 'Join Your Next Scheduled Jam'
                  : 'No upcoming jams available',
              subtitle: nextJam != null
                  ? 'Scheduled on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(nextJam!.data['jam']['date']))}'
                  : 'You will need to sign up for upcoming jams',
              onTap: () {
                if (nextJam != null &&
                    nextJam!.data['jam']['zoom_link'] != null) {
                  _goToExternalLink(nextJam!.data['jam']['zoom_link']);
                }
              },
            ),

                        // Signal link Card
            const SizedBox(height: 10),
            StandardCard(
              icon: Icons.chat,
              title: "Join our Signal Chat",
              subtitle: "Connect with other members in our PhotoJam Signal group",
              onTap: () {
                _goToExternalLink(signalGroupUrl);
              },
            ),

            // Become a member Card
            if (userRole == 'nonmember') ...[
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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

            // Master of the Month Section
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MasterOfTheMonthPage()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master of the Month',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sebastiano Salgado',
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Share the Jam Section
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share the Jam',
                  style: textTheme.headlineSmall,
                ),
                Image.asset(
                  'assets/images/qrcode.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
