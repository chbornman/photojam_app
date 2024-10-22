import 'package:flutter/material.dart';
import 'home_page.dart';  // Import home page
import 'journey_page.dart';  // Import journey page
import 'profile_page.dart';  // Import profile page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Jam',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),  // Use HomePage from home_page.dart
    JourneyPage(),  // Use JourneyPage from journey_page.dart
    ProfilePage(),  // Use ProfilePage from profile_page.dart
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Jam'),
        backgroundColor: Colors.amber,  // Colored top bar
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 0;  // Navigate to the Home Page (index 0)
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/icon/app_icon.png'), // App icon next to title
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),  // Hamburger menu icon
              onPressed: () {
                Scaffold.of(context).openEndDrawer();  // Open the end drawer
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
              leading: Icon(Icons.music_note),
              title: Text('Join the Jam'),
              onTap: () {
                Navigator.pop(context);  // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_run),
              title: Text('Current Jam Journey'),
              onTap: () {
                Navigator.pop(context);  // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Member Center'),
              onTap: () {
                Navigator.pop(context);  // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],  // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pedal_bike),
            label: 'Journey',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}