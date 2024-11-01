import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/pages/home/jamsignup_page.dart';
import 'package:photojam_app/pages/home/master_of_the_month_page.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appwrite/models.dart'; // Import for Appwrite Document model
import 'package:intl/intl.dart'; // Import for date formatting

class HomePage extends StatefulWidget {
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
        print("User ID is null, delaying fetch until user is authenticated.");
      }
    });
  }

  // Fetch jams from the database where the user has submissions
  Future<void> _fetchUserJams() async {
    final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
    final userId = Provider.of<AuthAPI>(context, listen: false).userid;

    // Fetch jams associated with the user's submissions
    final jams = await databaseApi.getUserJamsWithSubmissions(userId!);

    // Sort jams by date and find the next upcoming one
    jams.sort((a, b) {
      DateTime dateA = DateTime.parse(a.data['jam']['date']);
      DateTime dateB = DateTime.parse(b.data['jam']['date']);
      return dateA.compareTo(dateB);
    });

    setState(() {
      userJams = jams;
      try {
        // Find the first upcoming jam by date
        nextJam = userJams.firstWhere(
          (cal) =>
              DateTime.parse(cal.data['jam']['date']).isAfter(DateTime.now()),
        );
      } catch (e) {
        // If no upcoming jam is found, set nextJam to null
        nextJam = null;
      }
    });
  }

  // Function to launch the Zoom link
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
        // Enable scrolling
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Join the Jam section
            Text(
              'Join the Jam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Sign Up Now button at the top of Join the Jam section
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JamSignupPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, defaultButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                ),
                child: const Text('Sign Up Now'),
              ),
            ),
            SizedBox(height: 10),

            // Join next upcoming jam button with date
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (nextJam != null &&
                        nextJam!.data['jam']['zoom_link'] != null)
                    ? () => _goToZoomCall(nextJam!.data['jam']['zoom_link'])
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, defaultButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                ),
                child: Text(
                  nextJam != null
                      ? 'Join: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(nextJam!.data['jam']['date']))}'
                      : 'No upcoming jams available',
                ),
              ),
            ),
            SizedBox(height: 20),

            // Master of the Month section with a light grey background
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MasterOfTheMonthPage()), // Navigate to Master of the Month Page
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryAccentColor,
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
                padding:
                    const EdgeInsets.all(16.0), // Padding inside the container
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

            // Share the Jam section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share the Jam',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Image.asset(
                  'assets/images/qrcode.png', // Replace with the actual QR code image
                  width: 150, // Adjust the size of the QR code
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 30),

            // Conditionally render buttons for admin
            FutureBuilder<String?>(
              future:
                  Provider.of<AuthAPI>(context, listen: false).getUserRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData && snapshot.data == 'admin') {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to Add Jam page
                        },
                        child: Text('Add a Jam'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to Add Journey page
                        },
                        child: Text('Add a Journey'),
                      ),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}
