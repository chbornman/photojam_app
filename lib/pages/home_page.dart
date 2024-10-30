import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'signup_page.dart'; // Placeholder for the sign-up page
import 'master_of_the_month_page.dart'; // Placeholder for Master of the Month page

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        title: const Text('Home'),
      ),
      body: Padding(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage()),
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
                padding: const EdgeInsets.all(16.0), // Padding inside the container
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master of the Month',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Sebastiano Salgado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}