import 'package:photojam_app/pages/account_page.dart';
import 'package:photojam_app/pages/home_page.dart';
import 'package:photojam_app/pages/journey_page.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/pages/submissions_page.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    JourneyPage(),
    SubmissionsPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Jam'),
        backgroundColor: Colors.amber, // Colored top bar
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 0; // Navigate to the Home Page (index 0)
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
                'assets/icon/app_icon.png'), // App icon next to title
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu), // Hamburger menu icon
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // Open the end drawer
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.amber,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // Corresponds to Home tab
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_walk),
              title: Text('Journey'),
              onTap: () {
                setState(() {
                  _currentIndex = 1; // Corresponds to Journey tab
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Submissions'),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Corresponds to Submissions tab
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Account'),
              onTap: () {
                setState(() {
                  _currentIndex = 3; // Switches to Account screen
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: (_currentIndex >= 0 && _currentIndex < _screens.length) ? _currentIndex : 0,
  onTap: (index) {
    if (index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  },
  selectedItemColor: (_currentIndex >= 0 && _currentIndex < _screens.length) ? Colors.amber : Colors.grey,
  unselectedItemColor: Colors.grey,
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "Journey"),
    BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: "Submissions"),
    BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
  ],
),
    );
  }
}
