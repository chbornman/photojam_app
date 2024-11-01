import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/account_page.dart';
import 'package:photojam_app/pages/home/home_page.dart';
import 'package:photojam_app/pages/journeys/journey_page.dart';
import 'package:photojam_app/pages/admin/admin_page.dart';
import 'package:photojam_app/pages/submissions/submissions_page.dart';
import 'package:photojam_app/constants/constants.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Using FutureBuilder to retrieve the user role from AuthAPI
    return FutureBuilder<String?>(
      future: Provider.of<AuthAPI>(context, listen: false).getUserRole(),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for the user role
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // If there's an error or the role is not available, show an error or redirect to LoginPage
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("Error: Could not retrieve user role."));
          // Alternatively, you could navigate to LoginPage if authentication is required here.
        }

        final userRole = snapshot.data!;

        // Define screens based on user role
        List<Widget> _screens = [
          HomePage(),
          JourneyPage(),
          SubmissionsPage(),
          AccountPage(),
        ];

        // Add Admin Page if the user is an admin
        if (userRole == "admin") {
          _screens.add(AdminPage());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Photo Jam'),
            backgroundColor: accentColor, // Top bar color
            leading: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 0; // Navigate to the Home Page (index 0)
                });
              },
              child: Icon(Icons.home),
            ),
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.black, // Optional: selected icon/text color
            unselectedItemColor: accentColor, // Optional: unselected icon/text color
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journey'),
              BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'Submissions'),
              BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
              if (userRole == "admin")
                BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
            ],
          ),
        );
      },
    );
  }
}