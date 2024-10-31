import 'package:photojam_app/pages/account_page.dart';
import 'package:photojam_app/pages/home_page.dart';
import 'package:photojam_app/pages/journey_page.dart';
import 'package:photojam_app/pages/admin_page.dart'; // Importing Admin Page
import 'package:flutter/material.dart';
import 'package:photojam_app/pages/submissions_page.dart';
import 'package:photojam_app/constants/constants.dart';

class TabsPage extends StatefulWidget {
  final String userRole; // Added user role as a parameter

  const TabsPage({Key? key, required this.userRole}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define screens based on user role
    List<Widget> _screens = [
      HomePage(),
      JourneyPage(),
      SubmissionsPage(),
      AccountPage(),
    ];

    // Add Admin Page if the user is an admin
    if (widget.userRole == "admin") {
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
        backgroundColor: accentColor, // Set bottom bar color to accentColor
        selectedItemColor: Colors.black, // Optional: selected icon/text color
        unselectedItemColor:
            Colors.grey, // Optional: unselected icon/text color
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journey'),
          BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions), label: 'Submissions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Account'),
          if (widget.userRole == "admin")
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}
