import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/pages/home/jamsignup_page.dart';
import 'package:photojam_app/pages/home/master_of_the_month_page.dart';
import 'package:photojam_app/standard_button.dart';
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
        print("User ID is null, delaying fetch until user is authenticated.");
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

  void _goToZoomCall(String url) {
    final Uri zoomUri = Uri.parse(url);
    if (zoomUri.hasScheme) {
      launchUrl(zoomUri);
    } else {
      print("Invalid Zoom URL");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join the Jam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            standardButton(
              label: 'Sign Up Now',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamSignupPage()),
                );
              },
            ),
            standardButton(
              label: nextJam != null
                  ? 'Join: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(nextJam!.data['jam']['date']))}'
                  : 'No upcoming jams available',
              onPressed:
                  (nextJam != null && nextJam!.data['jam']['zoom_link'] != null)
                      ? () => _goToZoomCall(nextJam!.data['jam']['zoom_link'])
                      : null,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MasterOfTheMonthPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryAccentColor,
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master of the Month',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Sebastiano Salgado',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Image.asset(
                            'assets/images/photo1.jpeg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Image.asset(
                            'assets/images/photo2.jpeg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Image.asset(
                            'assets/images/photo3.jpeg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share the Jam',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Image.asset(
                  'assets/images/qrcode.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}
